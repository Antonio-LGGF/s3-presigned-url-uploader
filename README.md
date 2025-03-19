# S3 Pre-Signed URL Uploader

This project automates **secure file uploads** to an AWS S3 bucket using **pre-signed URLs**.  
It uses **AWS Lambda**, **Terraform**, and **PowerShell/cURL** for easy and secure file transfers.

## 🚀 Features
- **Pre-signed URLs**: Securely upload files without exposing AWS credentials.
- **AWS Lambda API**: Generates pre-signed URLs for S3 uploads.
- **Terraform Deployment**: Automates Lambda, IAM, and S3 setup.
- **PowerShell & cURL Support**: Upload files via CLI.

## 📦 Project Structure
```
├── lambda_function.py  # AWS Lambda function for generating pre-signed URLs
├── main.tf             # Terraform configuration for AWS resources
├── provider.tf         # Terraform provider settings
└── README.md           # Project documentation
```

## 🛠️ Prerequisites
- **AWS CLI** installed & configured (`aws configure`).
- **Terraform** installed (`terraform --version`).
- **An AWS S3 bucket** to store uploaded files.

## ⚡ Deployment Steps
### **1️⃣ Clone the Repository**
```sh
git clone https://github.com/YOUR_GITHUB_USERNAME/s3-presigned-url-uploader.git
cd s3-presigned-url-uploader
```

### **2️⃣ Deploy the Infrastructure (Terraform)**
```sh
terraform init
terraform apply -auto-approve
```

### **3️⃣ Get a Pre-Signed URL**
Run this command to request a pre-signed URL for uploading a file:
```powershell
$response = curl "https://your-api-gateway-url/get-presigned-url?file_name=myfile.csv"
$url = ($response.Content | ConvertFrom-Json).url
Write-Output $url
```

### **4️⃣ Upload a File Using the Pre-Signed URL**
```powershell
Invoke-WebRequest -Uri $url -Method Put -InFile "C:\path\to\myfile.csv" -ContentType "application/octet-stream"
```

## 🔥 Verify the Upload
Check if the file is in S3:
```sh
aws s3 ls s3://your-bucket-name/
```

## 📜 License
This project is **MIT licensed**. Feel free to use and improve it!
