#!/bin/bash
# Script to push Shelf Check image to Docker Hub
# Usage: ./push-image.sh [your-dockerhub-username]
# Example: ./push-image.sh omarbaddour1

if [ -z "$1" ]; then
    echo "Usage: ./push-image.sh <your-dockerhub-username>"
    echo "Example: ./push-image.sh omarbaddour1"
    echo ""
    echo "⚠️  Note: Use ONLY your Docker Hub username, not 'your-dockerhub-username'"
    exit 1
fi

# Remove 'your-dockerhub-' prefix if user mistakenly included it
DOCKERHUB_USER=${1#your-dockerhub-}
IMAGE_NAME="shelf-check-app"
TAG="latest"
FULL_IMAGE="${DOCKERHUB_USER}/${IMAGE_NAME}:${TAG}"

echo "🔍 Checking if image exists locally..."
if ! docker images | grep -q "${IMAGE_NAME}.*${TAG}"; then
    echo "❌ Image ${IMAGE_NAME}:${TAG} not found locally"
    echo "Building image first..."
    cd SC_DbApp
    docker build -t ${IMAGE_NAME}:${TAG} .
    cd ..
fi

echo "🏷️  Tagging image as ${FULL_IMAGE}..."
docker tag ${IMAGE_NAME}:${TAG} ${FULL_IMAGE}

echo "📤 Pushing to Docker Hub..."
docker push ${FULL_IMAGE}

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed ${FULL_IMAGE}"
    echo ""
    echo "📝 Update k8s-deployment.yaml with:"
    echo "   image: ${FULL_IMAGE}"
    echo "   imagePullPolicy: IfNotPresent"
    echo ""
    echo "Or run:"
    echo "   sed -i 's|image: shelf-check-app:latest|image: ${FULL_IMAGE}|' k8s-deployment.yaml"
    echo "   sed -i 's|imagePullPolicy: Never|imagePullPolicy: IfNotPresent|' k8s-deployment.yaml"
else
    echo "❌ Failed to push image. Make sure you're logged in:"
    echo "   docker login"
    exit 1
fi

