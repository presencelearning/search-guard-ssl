#!/bin/bash

#CA crts
aws --region us-west-2 s3 cp ca/root-ca.crt s3://presencelearning-devops/letsencrypt/svc/ca/root-ca.crt --sse
aws --region us-west-2 s3 cp ca/signing-ca.crt s3://presencelearning-devops/letsencrypt/svc/ca/signing-ca.crt --sse
