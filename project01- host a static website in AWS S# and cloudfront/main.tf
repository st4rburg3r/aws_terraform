resource "aws_s3_bucket" "bucket01" {
    bucket = var.bucket_name
  
}

#uploading the website files to the bucket
resource "aws_s3_object" "object01" {

    bucket = aws_s3_bucket.bucket01.id
    for_each = fileset("${path.module}/website_files", "**/*")  #iterating over all files in the website_files directory and creating an s3 object for each file
    
    
    key    = each.value  #the key of the s3 object is set to the relative path of the file within the website_files directory
    source = "${path.module}/website_files/${each.value}"  #the source of the s3 object is set to the absolute path of the file on the local filesystem
    etag = filemd5("${path.module}/website_files/${each.value}")  #the etag of the s3 object is set to the md5 hash of the file, which allows terraform to detect changes to the file and update the s3 object accordingly

    content_type = lookup({
        "html" = "text/html",
        "css"  = "text/css",
        "js"   = "application/javascript",
        "png"  = "image/png",
        "jpg"  = "image/jpeg",
        "jpeg" = "image/jpeg"
    }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")  #setting the content type of the s3 object based on the file extension, with a default of application/octet-stream for unknown file types



}

# creating a cloudfront distribution to serve the website from the s3 bucket

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.bucket01.bucket_regional_domain_name #has to be same as bucket name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

#   aliases = ["mysite.${local.my_domain}", "yoursite.${local.my_domain}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
#   ordered_cache_behavior {
#     path_pattern     = "/content/*"
#     allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = local.origin_id

#     forwarded_values {
#       query_string = false

#       cookies {
#         forward = "none"
#       }
#     }

#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#     compress               = true
#     viewer_protocol_policy = "redirect-to-https"
#   }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["IN", "CA", "GB", "DE"]
    } 
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}







#bucket policy to allow cloudfront to access the bucket
#authorize cloudfront to access the bucket by allowing s3:GetObject and s3:ListBucket permissions to the cloudfront service principal, with a condition that restricts access to requests originating from the specific cloudfront distribution

resource "aws_s3_bucket_policy" "allow_cf" {
  bucket = aws_s3_bucket.bucket01.id
  depends_on = [ aws_s3_bucket_public_access_block.block ]  #explicit dependency on the public access block resource to ensure it is created first
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFront",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": [
        "s3:GetObject"
        # "s3:ListBucket"
      ],
      "Resource": "${aws_s3_bucket.bucket01.arn}/*"
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "${aws_cloudfront_distribution.s3_distribution.arn}"
        }
      }
    }
  ]
})
}

#making sure the bucket is private
resource "aws_s3_bucket_public_access_block" "block" {
    bucket = aws_s3_bucket.bucket01.id  #implicit dependency on the bucket resource
    
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

#origin access control for cloudfront - authentication method for cloudfront to access the s3 bucket
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "project01-oac"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

