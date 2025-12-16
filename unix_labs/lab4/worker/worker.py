import pika
import time
 
def do_work(ch, method, props, body):
     n = int(body)
     result = fibonacci(n)
     ch.basic_publish(exchange = '', routing_key = props.reply_to, properties = pika.BasicProperties(correlation_id = props.correlation_id), body = result)
 
def fibonacci(n):
    if n <= 1:
        return str(n)
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return str(b)
 
time.sleep(15)
 
connection = pika.BlockingConnection(pika.ConnectionParameters('rabbitmq'))
channel = connection.channel()
channel.queue_declare(queue = 'fibonacci_queue')
channel.basic_consume(queue = 'fibonacci_queue', on_message_callback = do_work, auto_ack = True)
 
print("Исполнитель ждёт заявок...")
 
try:
    channel.start_consuming()
except KeyboardInterrupt:
    print("\nИсполнитель прекратил свою работу...")
finally:
    connection.close()
