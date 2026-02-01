#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>

// Tablica globalna
int numbers[10];

// Mutex do ochrony printf
pthread_mutex_t print_mutex;

// Funkcja wykonywana przez wątek
void* thread_function(void* arg) {
    // Rzutowanie argumentu na typ long, otrzymuje id
    long id = (long)arg;

    // Każdy wątek przetwarza co trzeci element
    for (int i = id; i < 10; i += 3) {
        int val = numbers[i];

        // Sekcja krytyczna - blokujemy mutex przed wypisaniem
        pthread_mutex_lock(&print_mutex);
        
        // Wypisanie zgodnie z formatem z zadania
        printf("[Wątek %ld] Element[%d] = %d\n", id, i, val);
        
        // Odblokowanie mutexa
        pthread_mutex_unlock(&print_mutex);
    }

    return NULL;
}

int main() {
    // Inicjalizacja liczb losowych
    srand(time(NULL));

    // Wypełnienie tablicy globalnej losowymi liczbami (0-99)
    printf("--- Tablica początkowa: ---\n");
    for (int i = 0; i < 10; i++) {
        numbers[i] = rand() % 100;
        printf("%d ", numbers[i]);
    }
    printf("\n---------------------------\n");

    // Inicjalizacja mutexa
    if (pthread_mutex_init(&print_mutex, NULL) != 0) {
        perror("Błąd mutexa");
        return 1;
    }

    // Tablica identyfikatorów wątków
    pthread_t threads[3];

    // Tworzenie 3 wątków roboczych
    for (long i = 0; i < 3; i++) {
        if (pthread_create(&threads[i], NULL, thread_function, (void*)i) != 0) {
            perror("Błąd tworzenia wątku");
            return 1;
        }
    }

    // Czekanie na zakończenie wszystkich wątków
    for (int i = 0; i < 3; i++) {
        pthread_join(threads[i], NULL);
    }

    // Zwolnienie zasobów
    pthread_mutex_destroy(&print_mutex);

    printf("--- Koniec programu ---\n");
    return 0;
}
