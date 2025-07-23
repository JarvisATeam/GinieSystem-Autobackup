import tkinter as tk
from tkinter import messagebox
import os
from datetime import datetime

home = os.path.expanduser("~")
train_log = os.path.join(home, "GinieSystem/Training/logs/train_gui_log.txt")
supp_log = os.path.join(home, "GinieSystem/Training/logs/supplements.txt")

def log_training():
    muscle = muscle_entry.get()
    exercise = exercise_entry.get()
    weight = weight_entry.get()
    reps = reps_entry.get()
    sets = sets_entry.get()
    form = form_entry.get()

    if not all([muscle, exercise, weight, reps, sets, form]):
        messagebox.showwarning("Mangler informasjon", "Du må fylle ut alle felt før du logger.")
        return

    date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"{date} | {muscle} | {exercise} | {weight}kg | {reps} reps x {sets} sett | Form: {form}\n"

    with open(train_log, "a") as file:
        file.write(line)

    form_val = int(form)
    if form_val < 5:
        feedback = "🤖 AI: Ta en lettere økt neste gang eller hvil lenger."
    elif form_val > 8:
        feedback = "🤖 AI: Vurder å øke vekt eller legge til et ekstra sett neste gang."
    else:
        feedback = "🤖 AI: Fortsett på samme nivå og fokuser på teknikk."

    messagebox.showinfo("Logget!", feedback)

def log_supplements():
    date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    cocktail = "Koffein + amfetamin pre-workout, NAD+, Lion’s Mane, BCAA (maskert stimulantbruk)"
    effect = "Samme cocktail som i går – fokusert, skjerpet, pumped"

    line = f"{date} | {cocktail} | Effekt: {effect}\n"

    with open(supp_log, "a") as file:
        file.write(line)

    messagebox.showinfo("Tilskudd logget!", "💊 Dagens stack er lagret i loggen.")

# GUI-oppsett
root = tk.Tk()
root.title("GinieTrainApp 🏋️ + 💊")
root.geometry("420x450")

tk.Label(root, text="Muskelgruppe:").pack()
muscle_entry = tk.Entry(root)
muscle_entry.pack()

tk.Label(root, text="Øvelse:").pack()
exercise_entry = tk.Entry(root)
exercise_entry.pack()

tk.Label(root, text="Vekt (kg):").pack()
weight_entry = tk.Entry(root)
weight_entry.pack()

tk.Label(root, text="Reps:").pack()
reps_entry = tk.Entry(root)
reps_entry.pack()

tk.Label(root, text="Sett:").pack()
sets_entry = tk.Entry(root)
sets_entry.pack()

tk.Label(root, text="Form (1-10):").pack()
form_entry = tk.Entry(root)
form_entry.pack()

tk.Button(root, text="✅ Logg økt", command=log_training).pack(pady=10)
tk.Button(root, text="💊 Logg dagens tilskudd", command=log_supplements).pack(pady=5)

root.mainloop()
