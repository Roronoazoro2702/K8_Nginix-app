#!/bin/bash
# Set variables
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo "Error: Unable to fetch project ID. Please set it with 'gcloud config set project <project-id>'."
    exit 1
fi
GOOGLE_CHAT_WEBHOOK="https://chat.googleapis.com/v1/spaces/AAQAsKz9raw/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=x2drLn2QVvXbLxLf_WC-x_4EpKwcwaOmehXcspBvbbY"
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
        --log-filter='logName:"/logs/cloudaudit.googleapis.com%2Factivity" protoPayload.methodName:("storage.buckets.create" OR "storage.buckets.update" OR "storage.buckets.delete" OR "beta.compute.instances.insert" OR "compute.instances.update" OR "compute.instances.delete" OR "cloudsql.instances.create" OR "cloudsql.instances.insert" OR "cloudsql.instances.clone" OR "cloudsql.instances.update" OR "cloudsql.instances.delete" OR "compute.instances.insert" OR "compute.instances.start" OR "container.projects.locations.clusters.create" OR "container.projects.locations.clusters.update" OR "container.projects.locations.clusters.delete" OR "container.projects.locations.clusters.nodePools.create" OR "container.projects.locations.clusters.nodePools.delete" OR "k8s.io/create" OR "google.cloud.functions.v1.CloudFunctionsService.CreateFunction" OR "google.cloud.functions.v1.CloudFunctionsService.UpdateFunction" OR "google.cloud.functions.v1.CloudFunctionsService.DeleteFunction" OR "google.devtools.cloudbuild.v1.CloudBuild.CreateBuild" OR "cloud.functions.create" OR "cloudfunctions.functions.create" OR "cloudfunctions.functions.update" OR "cloudfunctions.functions.delete" OR "cloudfunctions.functions.call" OR "google.monitoring.v3.AlertPolicyService.CreateAlertPolicy" OR "google.monitoring.v3.AlertPolicyService.UpdateAlertPolicy" OR "google.monitoring.v3.AlertPolicyService.DeleteAlertPolicy")' \
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
        --log-filter='logName:"/logs/cloudaudit.googleapis.com%2Factivity" protoPayload.methodName:("storage.buckets.create" OR "storage.buckets.update" OR "storage.buckets.delete" OR "beta.compute.instances.insert" OR "compute.instances.update" OR "compute.instances.delete" OR "cloudsql.instances.create" OR "cloudsql.instances.insert" OR "cloudsql.instances.clone" OR "cloudsql.instances.update" OR "cloudsql.instances.delete" OR "compute.instances.insert" OR "compute.instances.start" OR "container.projects.locations.clusters.create" OR "container.projects.locations.clusters.update" OR "container.projects.locations.clusters.delete" OR "container.projects.locations.clusters.nodePools.create" OR "container.projects.locations.clusters.nodePools.delete" OR "k8s.io/create" OR "google.cloud.functions.v1.CloudFunctionsService.CreateFunction" OR "google.cloud.functions.v1.CloudFunctionsService.UpdateFunction" OR "google.cloud.functions.v1.CloudFunctionsService.DeleteFunction" OR "google.devtools.cloudbuild.v1.CloudBuild.CreateBuild" OR "cloud.functions.create" OR "cloudfunctions.functions.create" OR "cloudfunctions.functions.update" OR "cloudfunctions.functions.delete" OR "cloudfunctions.functions.call" OR "google.monitoring.v3.AlertPolicyService.CreateAlertPolicy" OR "google.monitoring.v3.AlertPolicyService.UpdateAlertPolicy" OR "google.monitoring.v3.AlertPolicyService.DeleteAlertPolicy")' \
        --project=$PROJECT_ID
fi

# Update Cloud Function with updated method names
cat << 'EOF' > main.py
import base64
import json
import requests
import os

def track_resource_creation(event, context):
    """Processes Cloud Audit Logs for resource creation, modification, and deletion events"""
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
        
        # Define methods for creation, modification, and deletion
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
        modification_methods = [
            'storage.buckets.update',
            'compute.instances.update',
            'cloudsql.instances.update',
            'cloud.functions.update',
            'google.cloud.functions.v1.CloudFunctionsService.UpdateFunction',
            'google.monitoring.v3.AlertPolicyService.UpdateAlertPolicy'
        ]
        deletion_methods = [
            'storage.buckets.delete',
            'compute.instances.delete',
            'cloudsql.instances.delete',
            'cloudfunctions.functions.delete',
            'cloud.function.delete'
            'google.cloud.functions.v1.CloudFunctionsService.DeleteFunction',
            'google.monitoring.v3.AlertPolicyService.DeleteAlertPolicy'
        ]
        
        # Categorize the event
        event_type = 'Unknown'
        if method_name in creation_methods:
            event_type = 'Creation'
        elif method_name in modification_methods:
            event_type = 'Modification'
        elif method_name in deletion_methods:
            event_type = 'Deletion'
        
        if event_type != 'Unknown':
            # Determine service type
            service_map = {
                'storage.buckets.create': 'storage.googleapis.com',
                'storage.buckets.update': 'storage.googleapis.com',
                'storage.buckets.delete': 'storage.googleapis.com',
                'beta.compute.instances.insert': 'compute.googleapis.com',
                'compute.instances.update': 'compute.googleapis.com',
                'compute.instances.delete': 'compute.googleapis.com',
                'compute.instances.insert': 'compute.googleapis.com',
                'compute.instances.start': 'compute.googleapis.com',
                'cloudsql.instances.create': 'sqladmin.googleapis.com',
                'cloudsql.instances.insert': 'sqladmin.googleapis.com',
                'cloudsql.instances.clone': 'sqladmin.googleapis.com',
                'cloudsql.instances.update': 'sqladmin.googleapis.com',
                'cloudsql.instances.delete': 'sqladmin.googleapis.com',
                'container.projects.locations.clusters.create': 'container.googleapis.com',
                'container.projects.locations.clusters.nodePools.create': 'container.googleapis.com',
                'k8s.io/create': 'container.googleapis.com',
                'google.cloud.functions.v1.CloudFunctionsService.CreateFunction': 'cloudfunctions.googleapis.com',
                'google.cloud.functions.v1.CloudFunctionsService.UpdateFunction': 'cloudfunctions.googleapis.com',
                'google.cloud.functions.v1.CloudFunctionsService.DeleteFunction': 'cloudfunctions.googleapis.com',
                'google.devtools.cloudbuild.v1.CloudBuild.CreateBuild': 'cloudbuild.googleapis.com',
                'cloud.functions.create': 'cloudfunctions.googleapis.com',
                'cloudfunctions.functions.create': 'cloudfunctions.googleapis.com',
                'cloud.functions.update': 'cloudfunctions.googleapis.com',
                'cloud.function.delete': 'cloudfunctions.googleapis.com',
                'cloudfunctions.functions.delete': 'cloudfunctions.googleapis.com',
                'cloudfunctions.functions.call': 'cloudfunctions.googleapis.com',
                'google.monitoring.v3.AlertPolicyService.CreateAlertPolicy': 'monitoring.googleapis.com',
                'google.monitoring.v3.AlertPolicyService.UpdateAlertPolicy': 'monitoring.googleapis.com',
                'google.monitoring.v3.AlertPolicyService.DeleteAlertPolicy': 'monitoring.googleapis.com'
            }
            service_type = service_map.get(method_name, 'Unknown')
            
            # Prepare Google Chat message with resource location
            chat_message = {
                'text': (
                    f"*🚨GCP Resource {event_type} Detected in {resource_location}*\n\n"
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
        
        return 'No matching resource event'
    
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

echo "Setup complete! Alerts configured for resource creation, modification, and deletion actions in project '$PROJECT_ID' with Cloud Function in '$REGION'."