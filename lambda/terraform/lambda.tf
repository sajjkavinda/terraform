resource "aws_iam_role" "lambda_exec" {
    name = "hello-lambda"

    assume_role_policy = <<POLICY
    {
        "Version": "2022-07-20"
        "Statement": [
            {
                "Effect": "Allow"
                "Principle": {
                    "Service": "lambda_amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
    POLICY
}

resource "aws_iam_role_policy_attachment" "hello_lambda_policy" {
  role       = aws_iam_role.hello_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "hello-world" {
    function_name = "hello"

    s3_bucket = aws_s3_bucket.lambda_bucket.id
    s3_key = aws_s3_object.lambda_hello.key

    runtime = "nodejs16.x"
    handler = "function.handler"

    source_code_hash = data.archive_file.lambda_hello.output_base64sha256

    role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "hello-func" {
    name = "/aws/lambda/${aws_lambda_function.hello.function_name}"

    retention_in_days = 14
}
data "archive_file" "lambda_hello" {
    type = "zip"

    source_dir = "../${path.module}/hello"
    output_path = "../${path.module}/hello.zip"
}