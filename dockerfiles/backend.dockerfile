# Use a slim Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy only what's needed
COPY backend/app.py .
COPY backend/index.html .
COPY backend/requirements.txt .
COPY backend/sparkplug_b_pb2.py .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the app port
EXPOSE 8000

# Start the app
CMD ["python", "app.py"] 