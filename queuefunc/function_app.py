import azure.functions as func
import datetime
import json
import logging

app = func.FunctionApp()


@app.service_bus_queue_trigger(arg_name="azservicebus", queue_name="chefcito-queue",
                               connection="https://chefcito-namespace.servicebus.windows.net") 
def queuetaker(azservicebus: func.ServiceBusMessage):
    logging.info('Python ServiceBus Queue trigger processed a message: %s',
                azservicebus.get_body().decode('utf-8'))
    
