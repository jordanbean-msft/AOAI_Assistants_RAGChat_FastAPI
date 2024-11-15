# Azure OpenAI - FastAPI Assistants Wrapper with Streaming

# FastAPI Azure OpenAI Assistant - RAG Chat
  
This FastAPI application provides a set of endpoints to interact with an Azure OpenAI assistant to chat with a RAG store (Azure AI Search index). It allows you to create threads, upload files, and run the assistant, streaming the responses back to the client in real-time. This FastAPI app can be containerized using the `Dockerfile` from this repository and deployed to a container hosting service like Azure Container Apps or Azure Container Instances.
  
## Features  
  
- **Create Threads:** Start new threads for conversations with the assistant.  
- **Upload Files:** Upload files to the assistant and create threads with the uploaded files.  
- **Run Assistant:** Send messages to the assistant and receive real-time streamed responses.  
  
## Endpoints  
  
### 1. Create Thread  
  
**Endpoint:** `/create_thread`    
**Method:** POST  
  
**Description:** Creates a new thread using the Azure OpenAI client and returns the thread ID.  
  
**Response:**  
```json  
{  
  "thread_id": "string"  
}  
```

### 2. Upload File and Create Thread
 
**Endpoint:** `/upload_file_and_create_thread`
**Method:** POST

**Description:** Uploads a file to the assistant and creates a new thread with a message indicating the uploaded file.

**Request Body:**
```json
{
    "file_name": "string",
    "file_data": "base64-encoded string",
    "thread_id": "string"
}
```

**Response:**
```json
{
    "thread_id": "string"
}
```

### 3. Run Assistant

**Endpoint:** `/run_assistant`  
**Method:** POST  

**Description:** Runs the assistant on a given thread and streams the response back to the client in real-time.

**Request Body:**
```json
{
    "thread_id": "string",
    "message": "string"
}
```

**Response:**  
Streams the assistant's responses as plain text.

## Setup

1. **Clone the repository:**
        ```sh
        git clone https://github.com/your-repo/fastapi-azure-openai-assistant.git
        cd fastapi-azure-openai-assistant
        ```

2. **Create a virtual environment and activate it:**
        ```sh
        python -m venv venv
        source venv/bin/activate  # On Windows use `venv\Scripts\activate`
        ```

3. **Install the dependencies:**
        ```sh
        pip install -r requirements.txt
        ```

4. **Create a `.env` file and add your Azure OpenAI credentials:**
        ```sh

        AOAI_ENDPOINT=your_azure_openai_endpoint

        AOAI_KEY=your_azure_openai_api_key

        AOAI_ASSISTANT_ID=your_azure_openai_assistant_id

        AOAI_EMBEDDINGS_MODEL=your_embedding_model_deployment_name

        AI_SEARCH_ENDPOINT=your_azure_ai_search_endpoint_uri

        AI_SEARCH_KEY=your_azure_ai_search_service_key

        AI_SEARCH_INDEX=your_target_index_name

        AZURE_OPENAI_API_VERSION=2024-02-15-preview  # Optional, default is "2024-02-15-preview"
        ```

1. **Create your Azure OpenAI Assistant:**
        Run the `setup_create_assistant.ipynb` notebook to create your assistant in AOAI. Copy the assistant ID to the `.env` file.    

2. **Run the application:**
        ```sh
        uvicorn main:app --reload
        ```

3. **Access the API documentation:**
        Open your browser and go to [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs) to see the interactive API documentation provided by Swagger UI.


## Deploy to Azure

1. Make a copy of the `infra/sample-dev-main.tfvars.json` file, name it `main.tfvars.json` and update the values as needed.

1. Run the following command to build & deploy the solution.

   ```shell
   azd up
   ```

   The endpoints for the `api` and `web` will be printed at the end of deployment.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
