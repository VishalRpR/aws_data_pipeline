import boto3
import psycopg2
import json

from botocore.exceptions import NoCredentialsError

s3_client = boto3.client('s3')
bucket_name = "aws-data-pipeline-bucket-12345"
file_name = "data.json"

rds_host = "terraform-20241228132454533900000003.cfcus8qkqilf.ap-south-1.rds.amazonaws.com"
rds_user = "vishal"
rds_password = "vishal1234"
rds_db = "user_data_db"


def read_data_from_s3():
    try:
        response = s3_client.get_object(Bucket=bucket_name, Key=file_name)
        data = response['Body'].read().decode('utf-8')
        parsed_data = json.loads(data)  # Parse the string as JSON
        return parsed_data
      
    except NoCredentialsError:
        print("Credentials not available.")
        return None


def push_data_to_rds(data):
    try:
       
        connection = psycopg2.connect(
            host=rds_host,
            user=rds_user,
            password=rds_password,
            database=rds_db
        )
        cursor = connection.cursor()
        
      
        for record in data:
            query = "INSERT INTO users (id, name, email, age) VALUES (%s, %s, %s, %s)"
            cursor.execute(query, (record['id'], record['name'], record['email'], record['age']))
        
        connection.commit()
    except Exception as e:
        print("RDS Insertion Failed:", e)
        return False
    finally:
        if connection:
            connection.close()
    return True

if __name__ == "__main__":
    data = read_data_from_s3()
    if data:
        success = push_data_to_rds(data)
        if not success:
            print("Fallback to Glue")
