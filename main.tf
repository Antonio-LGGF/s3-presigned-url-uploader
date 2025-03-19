# ---------------------------------------------------------------
# AWS Terraform Configuration: S3 + Lambda for Pre-Signed URLs
# ---------------------------------------------------------------

# Create an S3 bucket where PDFs will be uploaded
resource "aws_s3_bucket" "pdf_bucket" {
  bucket = "machine-uploaded-pdfs"  # Unique S3 bucket name
  force_destroy = true  # Destroys the bucket when running terraform destroy
}

# ---------------------------------------------------------------
# IAM Role and Policies for Lambda
# ---------------------------------------------------------------

# IAM Role for the Lambda function (allows it to assume the role)
resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_presigned_url_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"  # Allows Lambda to assume this role
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"  # Lambda service is trusted
      }
    }]
  })
}

# IAM Policy for Lambda: Grants permission to upload to S3
resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_s3_presigned_url_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:PutObject"  # Allows Lambda to generate pre-signed URLs for uploads
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.pdf_bucket.arn}/*"  # Grants access to all objects in the bucket
      }
    ]
  })
}

# Attach the policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# attach the AmazonS3FullAccess policy
resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.lambda_role.name  # Ensure this matches your Lambda role variable
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


# ---------------------------------------------------------------
# Deploy Lambda Function to Generate Pre-Signed URLs
# ---------------------------------------------------------------

# Create a zip file of the Lambda function before deployment
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"  # The Python file containing the Lambda function
  output_path = "lambda.zip"  # The zipped output file for deployment
}

# Define the Lambda function that generates pre-signed URLs
resource "aws_lambda_function" "generate_presigned_url" {
  function_name    = "GeneratePreSignedURL"
  role             = aws_iam_role.lambda_role.arn  # Attach IAM role
  runtime          = "python3.8"  # Specify Python version
  handler          = "lambda_function.lambda_handler"  # Function entry point
  filename         = data.archive_file.lambda_zip.output_path  # The Lambda code package
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256  # Ensures new code deployment

  # Environment variable to pass the S3 bucket name to Lambda
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.pdf_bucket.bucket
    }
  }
}

# ---------------------------------------------------------------
# API Gateway to Expose Lambda for Pre-Signed URL Requests
# ---------------------------------------------------------------

# Create an HTTP API Gateway to allow external access to Lambda
resource "aws_apigatewayv2_api" "api" {
  name          = "PresignedURLAPI"
  protocol_type = "HTTP"  # Use HTTP API instead of REST API for simplicity
}

# API Gateway Integration: Connect API Gateway to the Lambda function
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id  # Link to the API Gateway
  integration_type = "AWS_PROXY"  # Use Lambda proxy integration
  integration_uri  = aws_lambda_function.generate_presigned_url.invoke_arn  # Lambda function to invoke
}

# Define the API Gateway route that triggers the Lambda function
resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /get-presigned-url"  # API Gateway will listen for this endpoint
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Automatically deploy the API Gateway
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "prod"  # Production stage
  auto_deploy = true  # Enables automatic deployment of changes
}

# ---------------------------------------------------------------
# Permissions for API Gateway to Invoke Lambda
# ---------------------------------------------------------------

# Allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_presigned_url.function_name
  principal     = "apigateway.amazonaws.com"
}

# ---------------------------------------------------------------
# Output the API Gateway URL for External Use
# ---------------------------------------------------------------

output "api_url" {
  value = "${aws_apigatewayv2_api.api.api_endpoint}/prod/get-presigned-url"
  description = "API Gateway URL to request pre-signed URLs for S3 uploads"
}
