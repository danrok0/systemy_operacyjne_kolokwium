#!/bin/bash

# Sprawdzenie argumentu (ścieżka do katalogu)
if [ "$#" -ne 1 ]; then
    echo "Użycie: $0 <ścieżka_do_katalogu>"
    exit 1
fi

DIR="$1"

# Sprawdzenie, czy katalog istnieje
if [ ! -d "$DIR" ]; then
    echo "Błąd: Katalog '$DIR' nie istnieje."
    exit 1
fi

LOG_FILE="report.log"
SAFE_MODE=0      # 0 = Normalny (usuwa), 1 = Safe Mode (tylko ostrzega)
REMOVED_COUNT=0  # Licznik usuniętych plików do statystyk

# --- OBSŁUGA SYGNAŁÓW

# Funkcja dla SIGINT
handle_sigint() {
    echo ""
    echo "--- ZAKOŃCZONO ---"
    echo "Statystyka: Usunięto łącznie $REMOVED_COUNT plików."
    exit 0
}

# Funkcja dla SIGUSR1 (Przełączanie trybu)
handle_sigusr1() {
    if [ "$SAFE_MODE" -eq 0 ]; then
        SAFE_MODE=1
        echo "[SYSTEM] Przełączono w TRYB SAFE MODE (Tylko ostrzeganie)."
    else
        SAFE_MODE=0
        echo "[SYSTEM] Przełączono w TRYB NORMALNY (Usuwanie aktywne)."
    fi
}

# Rejestracja sygnałów
trap 'handle_sigint' SIGINT
trap 'handle_sigusr1' SIGUSR1

echo "Start monitorowania katalogu: '$DIR'"
echo "PID procesu: $$ (Użyj 'kill -SIGUSR1 $$' aby przełączyć tryb)"

#  Pętla nieskończona
while true; do
    # Liczymy tylko pliki (-type f), pomijamy katalogi wewnątrz
    FILE_COUNT=$(find "$DIR" -maxdepth 1 -type f | wc -l)

    # Logika: Jeśli plików > 5
    if [ "$FILE_COUNT" -gt 5 ]; then
        
        # Znajdź najstarszy plik (ls -t sortuje od najnowszego, tail -1 bierze ostatni)
        # ls -1t wypisuje po jednym w linii
        OLDEST_FILE=$(ls -1t "$DIR" | tail -n 1)

        # Sprawdzenie czy udało się znaleźć nazwę (zabezpieczenie)
        if [ -n "$OLDEST_FILE" ]; then
            if [ "$SAFE_MODE" -eq 1 ]; then
                echo "[SAFE MODE] Przekroczono limit ($FILE_COUNT). Najstarszy plik: '$OLDEST_FILE' (Nie usuwam)."
            else
                # Konstrukcja pełnej ścieżki (wymagane cudzysłowy dla spacji)
                FULL_PATH="$DIR/$OLDEST_FILE"
                
                # Próba usunięcia
                if rm "$FULL_PATH"; then
                    # Pobranie daty w formacie dla loga
                    DATE_NOW=$(date "+%Y-%m-%d %H:%M:%S")
                    
                    # Logowanie
                    echo "[$DATE_NOW] Usunięto $OLDEST_FILE" >> "$LOG_FILE"
                                        echo "[USUNIĘTO] $OLDEST_FILE (Liczba plików była: $FILE_COUNT)"
                    ((REMOVED_COUNT++))
                else
                    echo "[BŁĄD] Nie udało się usunąć pliku: $OLDEST_FILE"
                fi
            fi
        fi
    fi

    sleep 2
done
