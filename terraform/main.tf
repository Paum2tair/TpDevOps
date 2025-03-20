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

//----------Compression de lambda.js----------//
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "../lambda/"
  output_path = "lambda.zip"
}


//----------Définition de la lambda----------//

resource "aws_lambda_function" "lambda" {
  function_name = "groupe1-lambda"
  filename      = "lambda.zip"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda.handler"
  runtime       = "nodejs20.x"

  # Déclenche la mise à jour si le hash du fichier change
  source_code_hash = filebase64sha256("lambda.zip")
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
  description = "L'API pour la lambda du groupe 1"

}

//----------Définition de la ressource de l'API gateway----------//

resource "aws_api_gateway_resource" "lambda_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "lambda"
}

//----------Définition de la méthode de l'API gateway----------//

resource "aws_api_gateway_method" "lambda_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.lambda_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

//----------Intégration de la lambda dans l'API----------//

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.lambda_resource.id
  http_method             = aws_api_gateway_method.lambda_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

//----------Création des permissions d'accès à la lambda pour l'API----------//


resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

//----------Déploiement de l'API Gateway----------//

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  depends_on  = [aws_api_gateway_integration.lambda_integration]
}


//----------Définition du stage de l'API Gateway----------//
resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
}

//----------Output de l'URL de l'API Gateway----------//

output "api_gateway_url" {
  value       = "${aws_api_gateway_stage.api_stage.invoke_url}/lambda"
  description = "L'URL d'invocation de l'API Gateway"
}