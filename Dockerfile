# Use official Python image
FROM python:3.13-slim

# Set working directory
WORKDIR /app

# Copy requirements and source
COPY redirects.yml app.py ./

# Install dependencies
RUN pip install flask pyyaml

# Expose Flask default port
EXPOSE 666

# Run the Flask app
CMD ["python", "app.py"]
