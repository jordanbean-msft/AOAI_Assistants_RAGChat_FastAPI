from fastapi import FastAPI, Request, HTTPException  # Import necessary modules from FastAPI  
from fastapi.responses import StreamingResponse  # Import StreamingResponse for streaming responses  
from dotenv import load_dotenv  # Import load_dotenv to load environment variables from a .env file  
import os  # Import os for operating system related functions  
import base64  # Import base64 for encoding and decoding base64 data  
from pydantic import BaseModel  # Import BaseModel from pydantic for data validation  
import threading  # Import threading for creating and managing threads  
import queue  # Import queue for creating a queue to handle data between threads  
import tempfile  # Import tempfile for creating temporary files and directories  
import json
from azure.core.credentials import AzureKeyCredential
from azure.search.documents.models import VectorizedQuery
from azure.search.documents import SearchClient
  
app = FastAPI()  # Create a FastAPI app instance  
load_dotenv()  # Load environment variables from a .env file  
  
from typing_extensions import override  # Import override for method overriding  
from openai import AssistantEventHandler, OpenAI, AzureOpenAI  # Import necessary classes from OpenAI SDK  
  
global client, assistant  # Declare global variables for client and assistant  
  
# Initialize the AzureOpenAI client with environment variables  
client = AzureOpenAI(  
    azure_endpoint=os.environ["AOAI_ENDPOINT"],  
    api_key=os.environ["AOAI_KEY"],  
    api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview"),  
)  
  
# Retrieve the assistant using the client  
assistant = client.beta.assistants.retrieve(  
    os.environ['AOAI_ASSISTANT_ID']  
)  
  
@app.post("/create_thread")  
def create_thread():  
    thread = client.beta.threads.create()  # Create a new thread using the client  
    return thread.id  # Return the thread ID  
  
def retrieve_documents(keywords:str, document_count: int) -> str:
    search_key = os.environ['AI_SEARCH_KEY']
    search_endpoint = os.environ['AI_SEARCH_ENDPOINT']

    index_name = os.environ['AI_SEARCH_INDEX']
    embedding_model = os.environ['AOAI_EMBEDDINGS_MODEL']
    
    # Create a SearchClient object
    credential = AzureKeyCredential(search_key)
    client = SearchClient(endpoint=search_endpoint, index_name=index_name, credential=credential)
    vector_queries = VectorizedQuery(vector=generate_embeddings(keywords, embedding_model), k_nearest_neighbors=document_count, fields="embedding")
    results = client.search(search_text=keywords, 
                            select=['content', 'sourcepage', 'sourcefile'],
                            vector_queries=[vector_queries], 
                            top=document_count)
    
    return json.dumps(list(results))

def generate_embeddings(text, embedding_model_deployment):
    client = AzureOpenAI(
        azure_endpoint=os.environ['AOAI_ENDPOINT'], api_key=os.environ['AOAI_KEY'], api_version="2024-02-15-preview"
    )
    response = client.embeddings.create(input=text, model=embedding_model_deployment)
    return response.data[0].embedding



class RunAssistantRequest(BaseModel):  
    thread_id: str  
    message: str  
  
@app.post("/run_assistant")  
async def run_assistant(request: RunAssistantRequest):  
    thread_id = request.thread_id  
    user_message = request.message  
    count = 0  
  
    def generate_response():  
        q = queue.Queue()  # Create a queue to handle data between threads  
  
        # Define the EventHandler class  
        class EventHandler(AssistantEventHandler):  
            def __init__(self, client, thread_id):  
                super().__init__()  # Call the parent constructor  
                self.queue = q  
                self.client = client  
                self.thread_id = thread_id
                self.status = ''  
                self.tool_call_active = False  
  
            @override  
            def on_text_created(self, text) -> None:  
                pass  
  
            @override  
            def on_tool_call_created(self, tool_call):  
                if self.status != 'toolcall_created':  
                    self.status = 'toolcall_created'  
                    self.tool_call_active = True  
                if tool_call.type == 'code_interpreter':  
                    self.queue.put('<i>Launching Code Interpreter...</i>\n')  
                    self.queue.put("<pre><code>")  
                if tool_call.type == 'function':
                    if tool_call.function.name == 'retrieve_documents':
                        # self.queue.put('<i>Retrieving Documents...</i><br>\n\n')  
                        pass

  
            @override  
            def on_tool_call_delta(self, delta, snapshot) -> None:  
                if self.status != 'toolcall_delta':  
                    self.status = 'toolcall_delta'  
                if delta.type == 'code_interpreter':  
                    if self.tool_call_active == False:  
                        self.queue.put('<pre><code>')  
                        self.tool_call_active = True  
                    if delta.code_interpreter.input:  
                        self.queue.put(delta.code_interpreter.input)  
                    if delta.code_interpreter.outputs:  
                        for output in delta.code_interpreter.outputs:  
                            if output.type == "logs":  
                                self.queue.put(f"\n{output.logs}\n")  
                if delta.type == 'function':
                    if delta.function.name == 'retrieve_documents':
                       pass
  
            @override  
            def on_tool_call_done(self, tool_call) -> None:  
                if self.status != 'toolcall_done':  
                    self.status = 'toolcall_done'  
                if tool_call.type == 'code_interpreter':  
                    self.queue.put('</code></pre>')  
                    self.queue.put('\n')  
                    self.tool_call_active = False  
                if tool_call.type == 'function':
                    self.tool_call_active = False
                    # print("Tool call done")
  
            @override  
            def on_message_created(self, message) -> None:  
                if self.status != 'message_created':  
                    self.status = 'message_created'  
                pass  
  
            @override  
            def on_message_delta(self, delta, snapshot) -> None:  
                # print(delta)
                if self.status != 'message_delta':  
                    self.status = 'message_delta'  
                for content in delta.content:  
                    if content.type == 'image_file':  
                        img_bytes = self.client.files.content(content.image_file.file_id).read()  
                        # Encode image as base64 and send as data URL  
                        encoded_image = base64.b64encode(img_bytes).decode('utf-8')  
                        data_url = f'<img width="750px" src="data:image/png;base64,{encoded_image}"/><br>'  
                        self.queue.put(data_url)  
                        self.queue.put('\n')  
                        self.queue.put('\n')  
                    elif content.type == 'text':  
                        self.queue.put(content.text.value)  
  
            @override  
            def on_message_done(self, message) -> None:  
                if self.status != 'message_done':  
                    self.status = 'message_done'  
                self.queue.put('\n')  
                pass  

            @override
            def on_event(self, event) -> None:
                if event.event == "thread.run.requires_action":
                    tool_outputs = []
                    for tool_call in event.data.required_action.submit_tool_outputs.tool_calls:
                        args = json.loads(tool_call.function.arguments)
                        self.queue.put(f'<i>Retrieving Documents...</i> {args} <br><br>\n\n') 
                        results = retrieve_documents(args['keywords'], args['document_count'])
                        tool_outputs.append({
                            "tool_call_id": tool_call.id,
                            "output": results
                        })
                    with self.client.beta.threads.runs.submit_tool_outputs_stream(
                        thread_id=self.thread_id,
                        run_id=event.data.id,
                        tool_outputs=tool_outputs,
                        event_handler=EventHandler(self.client, self.thread_id)
                    ) as stream:
                        stream.until_done()        
                   
            
        # Function to run the SDK code  
        def run_assistant_code():  
            # Send the user message  
            client.beta.threads.messages.create(  
                thread_id=thread_id,  
                role="user",  
                content=user_message,  
            )  
            handler = EventHandler(client, thread_id)  
            # Use the stream SDK helper with the EventHandler  
            with client.beta.threads.runs.stream(  
                thread_id=thread_id,  
                assistant_id=assistant.id,  
                event_handler=handler,  
            ) as stream:  
                stream.until_done()  
             
            # Indicate completion  
            q.put(None)  
  
        # Start the SDK code in a separate thread  
        sdk_thread = threading.Thread(target=run_assistant_code)  
        sdk_thread.start()  
  
        # Read items from the queue and yield them  
        while True:  
            item = q.get()  
            if item is None:  
                break  
            item_with_line_breaks = item  
            yield item_with_line_breaks  
  
        sdk_thread.join()  
  
    return StreamingResponse(generate_response(), media_type="text/plain")  
