import base64
import json

from google.cloud import bigquery


def hello_pubsub(event, context):
    """Background Cloud Function to be triggered by Pub/Sub.
    Args:
         event (dict):  The dictionary with data specific to this type of
                        event. The `@type` field maps to
                         `type.googleapis.com/google.pubsub.v1.PubsubMessage`.
                        The `data` field maps to the PubsubMessage data
                        in a base64-encoded string. The `attributes` field maps
                        to the PubsubMessage attributes if any is present.
         context (google.cloud.functions.Context): Metadata of triggering event
                        including `event_id` which maps to the PubsubMessage
                        messageId, `timestamp` which maps to the PubsubMessage
                        publishTime, `event_type` which maps to
                        `google.pubsub.topic.publish`, and `resource` which is
                        a dictionary that describes the service API endpoint
                        pubsub.googleapis.com, the triggering topic's name, and
                        the triggering event type
                        `type.googleapis.com/google.pubsub.v1.PubsubMessage`.
    Returns:
        None. The output is written to Cloud Logging.
    """

    project_id = 'PLACEHOLDER_PROJECT_ID'
    dataset_id = 'PLACEHOLDER_DATASET_ID'
    table_id = 'PLACEHOLDER_TABLE_ID'

    print("""This Function was triggered by messageId {} published at {} to {}
    """.format(context.event_id, context.timestamp, context.resource["name"]))

    # Pub/Sub encodes the message in base64
    pubsub_message = base64.b64decode(event['data']).decode('utf-8')
    print(f'Received Pub/Sub message: {pubsub_message}')

    table_fqid = f"{project_id}.{dataset_id}.{table_id}"

    print(f'Loading data into {table_fqid}')

    # Construct a BigQuery client object.
    client = bigquery.Client()

    row_to_insert = [json.loads(pubsub_message)]
    errors = client.insert_rows_json(table_fqid, row_to_insert)  # Make an API request.
    if not errors:
        print("New rows have been added.")
    else:
        print("Encountered errors while inserting rows: {}".format(errors))
