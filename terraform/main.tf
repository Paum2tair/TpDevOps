//----------Définition du provider----------//

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-3"
}

//----------Compressage de lambda.py----------//
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "../lambda.js"
  output_path = "lambda.zip"
}


//----------Définition de la lambda----------//

resource "aws_lambda_function" "lambda" {
  function_name = "groupe1-lambda"
  filename      = "lambda.zip"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda.handler"
  runtime       = "nodejs14.x"
}


//----------Définition du rôle de la lambda----------//

resource "aws_iam_role" "lambda" {
  name = "groupe1-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      },
    ]
  })
}

//----------Définition de l'API gateway----------//

resource "aws_api_gateway_rest_api" "api" {
  name        = "groupe1-api"
  description = "This is my API for my lambda"

}


//----------Output de l'URL de l'API Gateway----------//

output "api_gateway_url" {
  value = aws_api_gateway_rest_api.api.execution_arn
  description = "L'URL d'invocation de l'API Gateway"
}