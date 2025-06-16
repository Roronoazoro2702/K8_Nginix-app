import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as awsx from "@pulumi/awsx";

// Create an AWS resource (S3 Bucket)
const bucket = new aws.s3.Bucket("my-vulnerable-bucket", {
    acl: "public-read",               // Security issue: public access
    forceDestroy: true,
    website: {
        indexDocument: "index.html",
        errorDocument: "error.html",
    },
    // Missing encryption configuration
    // Missing versioning configuration
    // Missing logging configuration
    tags: {
        Environment: "Production",
        Name: "WebsiteBucket",
    },
});

// Create an AWS IAM user with excessive permissions
const user = new aws.iam.User("deployment-user", {
    name: "deployment-user",
    path: "/system/",
});

// Create access keys for the IAM user
const accessKey = new aws.iam.AccessKey("deploymentUserAccessKey", {
    user: user.name,
});

// Create an excessively permissive policy
const policyDocument = aws.iam.getPolicyDocumentOutput({
    statements: [{
        effect: "Allow",
        actions: ["*"],               // Security issue: wildcard permission
        resources: ["*"],            // Security issue: wildcard resource
    }],
});

const policy = new aws.iam.Policy("deploymentUserPolicy", {
    name: "DeploymentUserPolicy",
    description: "Policy for the deployment user",
    policy: policyDocument.json,
});

// Attach the policy to the user
const policyAttachment = new aws.iam.UserPolicyAttachment("deploymentUserPolicyAttachment", {
    user: user.name,
    policyArn: policy.arn,
});

// Export the bucket name and URL
export const bucketName = bucket.id;
export const bucketUrl = pulumi.interpolate`http://${bucket.websiteDomain}`;
export const accessKeyId = accessKey.id;
export const secretAccessKey = accessKey.secret;  // Security issue: exposing secret