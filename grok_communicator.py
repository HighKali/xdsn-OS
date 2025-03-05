import os
import time
import threading
import socket
import pygame
import json
from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes
from Crypto.PublicKey import RSA
from Crypto.Signature import pkcs1_15
from Crypto.Hash import SHA256
from datetime import datetime, timedelta

# Simulazione di Hyperledger Fabric (in un progetto reale, useresti fabric-sdk-py)
class Blockchain:
    def __init__(self):
        self.chain = []
        self.pending_transactions = []
        self.create_genesis_block()

    def create_genesis_block(self):
        genesis_block = {"index": 0, "timestamp": str(datetime.now()), "transactions": [], "previous_hash": "0"}
        self.chain.append(genesis_block)

    def add_transaction(self, sender, receiver, data):
        transaction = {"sender": sender, "receiver": receiver, "data": data, "timestamp": str(datetime.now())}
        self.pending_transactions.append(transaction)

    def mine_block(self):
        if not self.pending_transactions:
            return False
        last_block = self.chain[-1]
        new_block = {
            "index": len(self.chain),
            "timestamp": str(datetime.now()),
            "transactions": self.pending_transactions,
            "previous_hash": SHA256.new(str(last_block).encode()).hexdigest()
        }
        self.chain.append(new_block)
        self.pending_transactions = []
        return True

# Crittografia AES-256
key = get_random_bytes(32)  # 256 bit
iv = get_random_bytes(16)   # 128 bit IV

def encrypt(data):
    cipher = AES.new(key, AES.MODE_CBC, iv)
    padded_data = data + b" " * (16 - len(data) % 16)
    return cipher.encrypt(padded_data)

def decrypt(data):
    cipher = AES.new(key, AES.MODE_CBC, iv)
    return cipher.decrypt(data).rstrip(b" ")

# Generazione chiavi RSA per login usa-e-getta
class DisposableLogin:
    def __init__(self):
        self.key_pairs = {}
        self.expiry_time = 300  # 5 minuti

    def generate_temp_credentials(self, user_id):
        key = RSA.generate(2048)
        private_key = key.export_key()
        public_key = key.publickey().export_key()
        expiry = datetime.now() + timedelta(seconds=self.expiry_time)
        self.key_pairs[user_id] = {"private_key": private_key, "public_key": public_key, "expiry": expiry}
        return private_key, public_key

    def verify_signature(self, user_id, message, signature):
        if user_id not in self.key_pairs or datetime.now() > self.key_pairs[user_id]["expiry"]:
            return False
        public_key = RSA.import_key(self.key_pairs[user_id]["public_key"])
        h = SHA256.new(message.encode())
        try:
            pkcs1_15.new(public_key).verify(h, signature)
            return True
        except (ValueError, TypeError):
            return False

# Streaming e comunicazione
blockchain = Blockchain()
login_system = DisposableLogin()

def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(("127.0.0.1", 5555))
    server.listen(1)
    print("Server in ascolto...")
    while True:
        conn, addr = server.accept()
        data = conn.recv(1024)
        if not data:
            break
        user_id, message, signature = json.loads(data.decode()).values()
        if login_system.verify_signature(user_id, message, signature):
            decrypted_data = decrypt(message.encode())
            blockchain.add_transaction(user_id, "server", decrypted_data.decode())
            blockchain.mine_block()
            print(f"Ricevuto (decifrato): {decrypted_data.decode()}")
        else:
            print("Autenticazione fallita!")
        conn.close()

def start_client(user_id, message):
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client.connect(("127.0.0.1", 5555))
    encrypted_message = encrypt(message.encode())
    h = SHA256.new(encrypted_message)
    private_key = RSA.import_key(login_system.key_pairs[user_id]["private_key"])
    signature = pkcs1_15.new(private_key).sign(h)
    payload = json.dumps({"user_id": user_id, "message": encrypted_message.decode(), "signature": signature.hex()})
    client.send(payload.encode())
    client.close()

# Interfaccia Arcade
pygame.init()
screen = pygame.display.set_mode((800, 600))
pygame.display.set_caption("Grok Communicator")
font = pygame.font.Font(None, 36)
clock = pygame.time.Clock()

messages = []
input_text = ""
user_id = "user_" + str(int(time.time()))
private_key, public_key = login_system.generate_temp_credentials(user_id)

def server_thread():
    threading.Thread(target=start_server, daemon=True).start()

server_thread()
time.sleep(1)

running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_RETURN:
                if input_text:
                    start_client(user_id, input_text)
                    messages.append(f"Inviato: {input_text}")
                    input_text = ""
            elif event.key == pygame.K_BACKSPACE:
                input_text = input_text[:-1]
            else:
                input_text += event.unicode

    screen.fill((0, 0, 0))
    y = 20
    for msg in messages[-10:]:
        text_surface = font.render(msg, True, (0, 255, 0))
        screen.blit(text_surface, (20, y))
        y += 40

    input_surface = font.render(f"> {input_text}", True, (255, 255, 255))
    screen.blit(input_surface, (20, 500))
    pygame.display.flip()
    clock.tick(30)

pygame.quit()
