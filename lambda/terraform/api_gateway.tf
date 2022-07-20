resource "aws_apigatewayv2_api" "main" {
    name = "main"
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "dev" {
    api_id = aws_apigatewayv2_api.main.id

    name = "dev"
    auto_deploy = true

    access_log_settings {
        destination_arn = aws_cloudwatch_log_group.hello-func.arn

        format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
    }
}

resource "aws_cloudwatch_log_group" "api_gw" {
    name = "/aws/api-gw/${aws_apigatewayv2_api.main.name}"

    retention_in_days = 14
}

resource "aws_apigatewayv2_integration" "lambda_hello" {
    api_id = aws_apigatewayv2_api.main.id

    integration_uri = aws_lambda_function.hello-world.invoke_arn
    integration_type = "AWS_PROXY"
    integration_method = "POST"
}

resource "aws_apigatewayv2_route" "get-gw" {
    api_id = aws_apigatewayv2_api.main.id

    route_key = "GET /hello"
    target = "integrations/${aws_apigatewayv2_integration.lambda_hello.id}"
}

resource "aws_apigatewayv2_route" "post-gw" {   
    api_id = aws_apigatewayv2_api.main.id

    route_key = "POST /hello"
    target = "integrations/${aws_apigatewayv2_integration.lambda_hello.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

output "hello_base_url" {
  value = aws_apigatewayv2_stage.dev.invoke_url
}