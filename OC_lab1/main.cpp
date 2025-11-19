#include <iostream>
#include <pthread.h>
#include <unistd.h>
using namespace std;

pthread_cond_t cond1 = PTHREAD_COND_INITIALIZER;
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
char ready = 0;

void* provider_work(void* args) {
    while (true) {
        sleep(1);
        pthread_mutex_lock(&lock);
        if (ready == 1)
        {
            pthread_mutex_unlock(&lock);
            continue;
        }
        ready = 1;
        printf("provided\n");
        pthread_cond_signal(&cond1);
        pthread_mutex_unlock(&lock);
    }
    return NULL;
}

void* consumer_work(void* args) {
    while (true) {
        pthread_mutex_lock(&lock);
        while (ready == 0)
        {
            pthread_cond_wait(&cond1, &lock);
            printf("awoke\n");
        }
        ready = 0;
        printf("consumed\n");
        pthread_mutex_unlock(&lock);
    }
    return NULL;
}

int main() {
    pthread_t provider, consumer;
    pthread_create(&consumer, NULL, consumer_work, NULL);
    pthread_create(&provider, NULL, provider_work, NULL);
    pthread_join(consumer, NULL);
    pthread_join(provider, NULL);
    return 0;
}