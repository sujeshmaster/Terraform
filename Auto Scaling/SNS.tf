
# Create IAM role for subscribers
resource "aws_iam_role" "sns_role" {
  name = "sns-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Create SNS topic
resource "aws_sns_topic" "my_topic" {
  name            = "${var.topic_name}"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}

# Delivery policies
resource "aws_sns_topic_policy" "topic_policy" {
  arn    = aws_sns_topic.my_topic.arn
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "example-topic-policy",
  "Statement": [
    {
      "Sid": "AllowS3Delivery",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "SNS:Publish",
      "Resource": "${aws_sns_topic.my_topic.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:s3:::example-bucket"
        }
      }
    }
  ]
}
POLICY
}

# Attach IAM policy to the role
resource "aws_iam_role_policy_attachment" "sns_subscriber_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.sns_role.name
}

# Email subscribers
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn            = aws_sns_topic.my_topic.arn
  protocol             = "${var.Protocol_Endpoint[0]}"
  endpoint             = "${var.Protocol_Endpoint[1]}"
  raw_message_delivery = false
}