#!/bin/bash
# Set variables
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo "Error: Unable to fetch project ID. Please set it with 'gcloud config set project <project-id>'."
    exit 1
fi
GOOGLE_CHAT_WEBHOOK="https://chat.googleapis.com/v1/spaces/AAAAPCMErXM/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=IHPFEmY27XchFyfGOQinWW7wufxXL8Yd0YAcXTUeQEo"
SINK_NAME="resource-creation-sink"
TOPIC_NAME="audit-logs-topic"
FUNCTION_NAME="track_resource_creation"
REGION="us-central1"  # Single region for Cloud Function deployment

# Check and create/update Pub/Sub Topic (project-wide)
echo "Checking if Pub/Sub topic '$TOPIC_NAME' exists in project '$PROJECT_ID'..."
TOPIC_EXISTS=$(gcloud pubsub topics list --project=$PROJECT_ID --filter="name:$TOPIC_NAME" --format="value(name)" 2>/dev/null)
if [ -z "$TOPIC_EXISTS" ]; then
    echo "Creating Pub/Sub topic '$TOPIC_NAME'..."
    gcloud pubsub topics create $TOPIC_NAME --project=$PROJECT_ID
else
    echo "Pub/Sub topic '$TOPIC_NAME' already exists. No update needed."
fi

# Check and create/update Logging Sink (project-wide)
echo "Checking if Logging sink '$SINK_NAME' exists in project '$PROJECT_ID'..."
SINK_EXISTS=$(gcloud logging sinks list --project=$PROJECT_ID --filter="name:$SINK_NAME" --format="value(name)" 2>/dev/null)
if [ -z "$SINK_EXISTS" ]; then
    echo "Creating Logging sink '$SINK_NAME'..."
    gcloud logging sinks create $SINK_NAME pubsub.googleapis.com/projects/$PROJECT_ID/topics/$TOPIC_NAME \
        --log-filter='logName:"/logs/cloudaudit.googleapis.com%2Factivity" protoPayload.methodName:"storage.buckets.create" OR protoPayload.methodName:"beta.compute.instances.insert" OR protoPayload.methodName:"cloudsql.instances.create" OR protoPayload.methodName:"cloudsql.instances.insert" OR protoPayload.methodName:"cloudsql.instances.clone" OR protoPayload.methodName:"compute.instances.insert" OR protoPayload.methodName:"compute.instances.start" OR protoPayload.methodName:"container.projects.locations.clusters.create" OR protoPayload.methodName:"container.projects.locations.clusters.nodePools.create" OR protoPayload.methodName:"k8s.io/create" OR protoPayload.methodName:"google.cloud.functions.v1.CloudFunctionsService.CreateFunction" OR protoPayload.methodName:"google.devtools.cloudbuild.v1.CloudBuild.CreateBuild" OR protoPayload.methodName:"cloud.functions.create" OR protoPayload.methodName:"cloudfunctions.functions.create" OR protoPayload.methodName:"cloudfunctions.functions.call" OR protoPayload.methodName:"google.monitoring.v3.AlertPolicyService.CreateAlertPolicy"' \
        --project=$PROJECT_ID
    # Grant Pub/Sub Publisher role to Logging service account
    LOGGING_SA=$(gcloud logging sinks describe $SINK_NAME --project=$PROJECT_ID --format="value(writerIdentity)" | sed 's/serviceAccount://')
    echo "Granting Pub/Sub Publisher role to $LOGGING_SA..."
    gcloud pubsub topics add-iam-policy-binding projects/$PROJECT_ID/topics/$TOPIC_NAME \
        --member=serviceAccount:$LOGGING_SA \
        --role=roles/pubsub.publisher \
        --project=$PROJECT_ID
else
    echo "Updating Logging sink '$SINK_NAME' filter..."
    gcloud logging sinks update $SINK_NAME \
        --log-filter='logName:"/logs/cloudaudit.googleapis.com%2Factivity" protoPayload.methodName:"storage.buckets.create" OR protoPayload.methodName:"beta.compute.instances.insert" OR protoPayload.methodName:"cloudsql.instances.create" OR protoPayload.methodName:"cloudsql.instances.insert" OR protoPayload.methodName:"cloudsql.instances.clone" OR protoPayload.methodName:"compute.instances.insert" OR protoPayload.methodName:"compute.instances.start" OR protoPayload.methodName:"container.projects.locations.clusters.create" OR protoPayload.methodName:"container.projects.locations.clusters.nodePools.create" OR protoPayload.methodName:"k8s.io/create" OR protoPayload.methodName:"google.cloud.functions.v1.CloudFunctionsService.CreateFunction" OR protoPayload.methodName:"google.devtools.cloudbuild.v1.CloudBuild.CreateBuild" OR protoPayload.methodName:"cloud.functions.create" OR protoPayload.methodName:"cloudfunctions.functions.create" OR protoPayload.methodName:"cloudfunctions.functions.call" OR protoPayload.methodName:"google.monitoring.v3.AlertPolicyService.CreateAlertPolicy"' \
        --project=$PROJECT_ID
fi

# Update Cloud Function with updated method names
cat << 'EOF' > main.py
import base64
import json
import requests
import os

def track_resource_creation(event, context):
    """Processes Cloud Audit Logs for resource creation events"""
    try:
        # Decode Pub/Sub message
        pubsub_message = base64.b64decode(event['data']).decode('utf-8')
        log_entry = json.loads(pubsub_message)
        
        # Extract relevant information
        protoPayload = log_entry.get('protoPayload', {})
        method_name = protoPayload.get('methodName', '')
        resource_name = protoPayload.get('resourceName', '').split('/')[-1]
        caller = protoPayload.get('authenticationInfo', {}).get('principalEmail', 'Unknown')
        # Extract the region from the resource location or request metadata
        resource_location = protoPayload.get('resourceLocation', {}).get('currentLocations', ['unknown'])[0] or 'unknown'
        if resource_location == 'unknown':
            request_metadata = protoPayload.get('requestMetadata', {})
            resource_location = request_metadata.get('callerSuppliedUserAgent', 'unknown').split('/')[0] or 'unknown'
        
        # Filter for resource creation and related methods
        creation_methods = [
            'storage.buckets.create',
            'beta.compute.instances.insert',
            'cloudsql.instances.create',
            'cloudsql.instances.insert',
            'cloudsql.instances.clone',
            'compute.instances.insert',
            'compute.instances.start',
            'container.projects.locations.clusters.create',
            'container.projects.locations.clusters.nodePools.create',
            'k8s.io/create',
            'google.cloud.functions.v1.CloudFunctionsService.CreateFunction',
            'google.devtools.cloudbuild.v1.CloudBuild.CreateBuild',
            'cloud.functions.create',
            'cloudfunctions.functions.create',
            'cloudfunctions.functions.call',
            'google.monitoring.v3.AlertPolicyService.CreateAlertPolicy'
        ]
        
        if method_name in creation_methods:
            # Determine service type
            service_map = {
                'storage.buckets.create': 'storage.googleapis.com',
                'beta.compute.instances.insert': 'compute.googleapis.com',
                'cloudsql.instances.create': 'sqladmin.googleapis.com',
                'cloudsql.instances.insert': 'sqladmin.googleapis.com',
                'cloudsql.instances.clone': 'sqladmin.googleapis.com',
                'compute.instances.insert': 'compute.googleapis.com',
                'compute.instances.start': 'compute.googleapis.com',
                'container.projects.locations.clusters.create': 'container.googleapis.com',
                'container.projects.locations.clusters.nodePools.create': 'container.googleapis.com',
                'k8s.io/create': 'container.googleapis.com',
                'google.cloud.functions.v1.CloudFunctionsService.CreateFunction': 'cloudfunctions.googleapis.com',
                'google.devtools.cloudbuild.v1.CloudBuild.CreateBuild': 'cloudbuild.googleapis.com',
                'cloud.functions.create': 'cloudfunctions.googleapis.com',
                'cloudfunctions.functions.create': 'cloudfunctions.googleapis.com',
                'cloudfunctions.functions.call': 'cloudfunctions.googleapis.com',
                'google.monitoring.v3.AlertPolicyService.CreateAlertPolicy': 'monitoring.googleapis.com'
            }
            service_type = service_map.get(method_name, 'Unknown')
            
            # Prepare Google Chat message with resource location
            chat_message = {
                'text': (
                    f"*🚨GCP Resource Action Detected in {resource_location}*\n\n"
                    f"*🔴EVENT*: {method_name}\n\n"
                    f"*👤USER*: {caller}\n\n"
                    f"*⚙️SERVICE*: {service_type}\n\n"
                    f"*📦RESOURCE*: {resource_name}\n\n"
                    f"*🌍REGION*: {resource_location}"
                )
            }
            
            # Send to Google Chat
            webhook_url = os.environ.get('GOOGLE_CHAT_WEBHOOK')
            response = requests.post(webhook_url, json=chat_message)
            
            print(f"Alert sent. Status: {response.status_code}")
            return response.status_code
        
        return 'No matching resource creation event'
    
    except Exception as e:
        print(f"Error processing log entry: {str(e)}")
        return None
EOF

# Add requirements.txt for dependencies
cat << 'EOF' > requirements.txt
functions-framework==3.*
requests>=2.25.0
EOF

# Deploy Cloud Function in a single region
echo "Processing region: $REGION"
echo "Checking if Cloud Function '$FUNCTION_NAME' exists in region '$REGION'..."
FUNCTION_EXISTS=$(gcloud functions list --project=$PROJECT_ID --region=$REGION --filter="name:$FUNCTION_NAME" --format="value(name)" 2>/dev/null)
if [ -z "$FUNCTION_EXISTS" ]; then
    echo "Creating Cloud Function '$FUNCTION_NAME' in region '$REGION'..."
    gcloud functions deploy $FUNCTION_NAME \
        --gen2 \
        --update-env-vars=GOOGLE_CHAT_WEBHOOK=$GOOGLE_CHAT_WEBHOOK,REGION=$REGION \
        --source=. \
        --runtime=python39 \
        --entry-point=track_resource_creation \
        --trigger-topic=$TOPIC_NAME \
        --region=$REGION \
        --project=$PROJECT_ID
else
    echo "Updating Cloud Function '$FUNCTION_NAME' in region '$REGION'..."
    gcloud functions deploy $FUNCTION_NAME \
        --update-env-vars=GOOGLE_CHAT_WEBHOOK=$GOOGLE_CHAT_WEBHOOK,REGION=$REGION \
        --source=. \
        --runtime=python39 \
        --entry-point=track_resource_creation \
        --trigger-topic=$TOPIC_NAME \
        --region=$REGION \
        --project=$PROJECT_ID
fi

# Clean up temporary files
rm main.py requirements.txt

echo "Setup complete! Alerts configured for specified resource actions in project '$PROJECT_ID' with Cloud Function in '$REGION'."
