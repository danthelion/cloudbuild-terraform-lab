import json

from google.cloud import pubsub_v1

# TODO(developer)
project_id = "project-id"
topic_id = "topic-id"

publisher = pubsub_v1.PublisherClient()
# The `topic_path` method creates a fully qualified identifier
# in the form `projects/{project_id}/topics/{topic_id}`
topic_path = publisher.topic_path(project_id, topic_id)

with open('example-payload.json') as f:
    data = json.load(f)

for message in data:
    print(message)
    # Data must be a bytestring
    # When you publish a message, the client returns a future.
    future = publisher.publish(topic_path, json.dumps(message).encode('utf-8'))
    print(future.result())

print(f"Published messages to {topic_path}.")
