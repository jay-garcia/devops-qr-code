from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import qrcode
import boto3
import os
from io import BytesIO
from typing import Union
from google.cloud import storage




# Loading Environment variable (AWS Access Key and Secret Key)
from dotenv import load_dotenv
load_dotenv()

from pydantic import BaseModel
class QRRequest(BaseModel):
    url: str

project_id = os.getenv("GCP_PROJECT_ID")

client = storage.Client(project=os.getenv("GCP_PROJECT_ID"))

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Welcome to Jesús's FastAPI application!"}

@app.get("/items/{item_id}")
def read_item(item_id: int, q: Union[str, None] = None):
    return {"item_id": item_id, "q": q}



# Allowing CORS for local testing
# origins = [
#     "http://localhost:3000"
# ]

origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# AWS S3 Configuration
# s3 = boto3.client(
#     's3',
#     aws_access_key_id= os.getenv("AWS_ACCESS_KEY"),
#     aws_secret_access_key= os.getenv("AWS_SECRET_KEY"))

bucket_name = 'my_generated_qrs' # Add your bucket name here

@app.get("/test")
def testStorageConnection():
    client = storage.Client(project="avid-water-471202-b4")

    # Try to get the bucket
    bucket = client.bucket(bucket_name)

    # Check if it exists
    if bucket.exists():
        print(f"Successfully connected to bucket: {bucket_name}")
    else:
        print(f"Bucket {bucket_name} does not exist or is not accessible")


@app.post("/generate-qr/")
async def generate_qr(request: QRRequest):
    url = request.url

    # Generate QR Code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    
    # Save QR Code to BytesIO object
    img_byte_arr = BytesIO()
    img.save(img_byte_arr, format='PNG')
    img_byte_arr.seek(0)

    # Generate file name for S3
    file_name = f"qr_codes/{url.split('//')[-1]}.png"

    try:
        # Upload to S3
        # s3.put_object(Bucket=bucket_name, Key=file_name, Body=img_byte_arr, ContentType='image/png', ACL='public-read')
        client = storage.Client(project="avid-water-471202-b4")
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(file_name)
        blob.upload_from_file(img_byte_arr, content_type="image/png")
        # blob.make_public()
        # Generate the S3 URL
        gcs_url = f"https://storage.googleapis.com/{bucket_name}/{file_name}"
        return {"qr_code_url": gcs_url}
    except Exception as e:
        print("QR Code Generation Failed: ", str(e))
        raise HTTPException(status_code=500, detail=str(e))
    