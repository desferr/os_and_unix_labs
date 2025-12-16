import socket
import select
import uuid
import queue
import pika
import time

response_queue = None

def response_handler(ch, method, properties, body):
    response_queue.put((properties.correlation_id, body.decode()))

time.sleep(15)

connection = pika.BlockingConnection(pika.ConnectionParameters('rabbitmq'))
channel = connection.channel()
channel.queue_declare(queue='fibonacci_queue')

reply_queue = channel.queue_declare(queue = '', exclusive = True).method.queue
response_queue = queue.Queue()

channel.basic_consume(queue = reply_queue, on_message_callback = response_handler, auto_ack = True)

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setblocking(False)
server.bind(('0.0.0.0', 5000))
server.listen()

print("Контроллер слушает порт 5000...")

clients = {}
correlation_map = {}

try:
    while True:
        sockets = [server] + list(clients.keys())
        selected_sockets, _, _ = select.select(sockets, [], [], 1.0)
        
        for sock in selected_sockets:
            if sock is server:
                client, _ = server.accept()
                client.setblocking(False)
                clients[client] = None
            else:
                try:
                    data = sock.recv(1024)
                    if not data:
                        del clients[sock]
                        sock.close()
                        continue
                    
                    n = int(data.decode().strip())
                    correlation_id = str(uuid.uuid4())
                    clients[sock] = correlation_id
                    correlation_map[correlation_id] = sock
                    
                    channel.basic_publish(exchange = '', routing_key = 'fibonacci_queue', properties = pika.BasicProperties(reply_to = reply_queue, correlation_id = correlation_id), body = str(n))
                    
                except (ValueError, ConnectionResetError, BrokenPipeError):
                    if sock in clients:
                        del clients[sock]
                    sock.close()
        
        try:
            while True:
                correlation_id, response = response_queue.get_nowait()
                if correlation_id in correlation_map:
                    client_socket = correlation_map[correlation_id]
                    if client_socket in clients:
                        client_socket.sendall((response + "\n").encode())
                        clients[client_socket] = None
                    del correlation_map[correlation_id]
        except queue.Empty:
            pass
        
        connection.process_data_events()
        
except KeyboardInterrupt:
    print("\nКонтроллер завершает свою работу...")
finally:
    for client_socket in clients:
        try:
            client_socket.close()
        except:
            pass
    server.close()
    connection.close()
