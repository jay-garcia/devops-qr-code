# devops-qr-code

This is the sample application for the DevOps Capstone Project.
It generates QR Codes for the provided URL, the front-end is in NextJS and the API is written in Python using FastAPI.

## Application

**Front-End** - A web application where users can submit URLs.

**API**: API that receives URLs and generates QR codes. The API stores the QR codes in cloud storage(AWS S3 Bucket).

## 🌐 Live Deployment

This FastAPI service is fully deployed on Google Kubernetes Engine (GKE) and connected with Google Cloud Platform (GCP) services for scalability and reliability.

You can access the live application directly in your browser:

http://34.26.82.149:80

**Deployment Highlights**

✅ Containerized with Docker and pushed to Google Container Registry (GCR)

✅ Deployed on Google Kubernetes Engine (GKE) with managed node pools

✅ Configured Load Balancer & Ingress to expose the service

✅ Integrated with Google Cloud IAM & Workload Identity for secure service-to-service communication

✅ Logs and monitoring via Cloud Logging & Cloud Monitoring

✅ Highly available, scalable, and production-ready setup

**🔄 Continuous Deployment (CI/CD)**

This project includes a GitHub Actions pipeline that automates deployments:

On every push to the main branch:

🏗 Docker image is built
📦 Image is pushed to Google Artifact Registry
🚀 GKE deployment is updated to use the new image automatically

This ensures the running application is always in sync with the latest changes in the repository, providing a seamless and production-grade development workflow.

## Running locally

### API

The API code exists in the `api` directory. You can run the API server locally:

- Clone this repo
- Make sure you are in the `api` directory
- Create a virtualenv by typing in the following command: `python -m venv .venv`
- Install the required packages: `pip install -r requirements.txt`
- Create a `.env` file, and add you AWS Access and Secret key, check  `.env.example`
- Also, change the BUCKET_NAME to your S3 bucket name in `main.py`
- Run the API server: `uvicorn main:app --reload`
- Your API Server should be running on port `http://localhost:8000`

### Front-end

The front-end code exits in the `front-end-nextjs` directory. You can run the front-end server locally:

- Clone this repo
- Make sure you are in the `front-end-nextjs` directory
- Install the dependencies: `npm install`
- Run the NextJS Server: `npm run dev`
- Your Front-end Server should be running on `http://localhost:3000`


## Goal

The goal is to get hands-on with DevOps practices like Containerization, CICD and monitoring.

## Authors & Contributors

Original Author: [Rishab Kumar](https://github.com/rishabkumar7)

Cloud Deployment & Adaptation: [Jesus Almanzar Garcia] (https://github.com/jay-garcia) – Adapted the project for production by:

-Containerizing with Docker
-Deploying on Google Kubernetes Engine (GKE)
-Configuring GCP services (IAM, Artifact Registry, Load Balancer, Monitoring)
-Implementing GitHub Actions CI/CD pipeline for automated builds and deployments

## License

[MIT](./LICENSE)
