clc;
clear;

% Ensure files save in script directory
cd(fileparts(mfilename('fullpath')));

Fs = 44100;
decay = 0.99;

% ===== PART 1: Open Strings =====
freqs_open = GuitarBackend.get_open_string_freqs();
string_names = {'E2','A2','D3','G3','B3','E4'};

fprintf('Generating open string notes...\n');

for i = 1:length(freqs_open)
    y = GuitarBackend.generate_synth(freqs_open(i), 2.0, decay, Fs);
    filename = sprintf('Note_%s.wav', string_names{i});
    GuitarBackend.save_audio(filename, y, Fs);
end

fprintf('Open string notes saved.\n');

% ===== PART 2: Melody =====
fprintf('Composing song...\n');

C3 = 130.81; D3 = 146.83; E3 = 164.81;
F3 = 174.61; G3 = 196.00; A3 = 220.00; B3 = 246.94;

note_freqs = [C3 C3 C3 D3 E3 E3 D3 E3 F3 G3 ...
              G3 G3 G3 E3 E3 E3 D3 D3 D3 C3 C3 C3 ...
              G3 F3 E3 D3 C3];

beat = 0.55;
q  = beat;
dq = beat * 1.5;
e  = beat * 0.5;
dh = beat * 3;
t2 = beat * 0.55;

note_durs = [q  q  dq e  dq ...
             dq e  dq e  dh ...
             t2 t2 t2 t2 t2 t2 t2 t2 t2 t2 t2 t2 ...
             dq e  dq e  dh];

total_dur = sum(note_durs) + 2;
total_samples = round(total_dur * Fs);

melody_track = zeros(total_samples,1);
chord_track = zeros(total_samples,1);

start_samples = round(cumsum([0, note_durs(1:end-1)]) * Fs) + 1;

% Melody
for i = 1:length(note_freqs)
    ring_dur = max(note_durs(i) * 1.8, 0.3);
    note_y = GuitarBackend.generate_synth(note_freqs(i), ring_dur, decay, Fs);

    s = start_samples(i);
    e_idx = min(s + length(note_y) - 1, total_samples);

    melody_track(s:e_idx) = melody_track(s:e_idx) + note_y(1:(e_idx-s+1));
end

% Chords
C_major = [C3, E3, G3];
F_major = [F3, A3, C3];
G_major = [G3, B3, D3];

chord_segs = {
    C_major, start_samples(1),  sum(note_durs(1:5));    
    F_major, start_samples(6),  sum(note_durs(6:7));    
    G_major, start_samples(8),  sum(note_durs(8:10));   
    C_major, start_samples(11), sum(note_durs(11:13));  
    G_major, start_samples(14), sum(note_durs(14:16));  
    C_major, start_samples(17), sum(note_durs(17:19));  
    G_major, start_samples(20), sum(note_durs(20:22));  
    G_major, start_samples(23), note_durs(23);          
    F_major, start_samples(24), note_durs(24);          
    C_major, start_samples(25), sum(note_durs(25:26));  
    C_major, start_samples(27), note_durs(27) + 1.5;    
};

for i = 1:size(chord_segs, 1)
    ch_freqs    = chord_segs{i, 1};
    ch_start    = chord_segs{i, 2};
    ch_dur_sec  = max(chord_segs{i, 3} * 1.8, 0.5);

    chord_y = GuitarBackend.generate_chord(ch_freqs, ch_dur_sec, 0.995, Fs);

    c_end   = min(ch_start + length(chord_y) - 1, total_samples);
    seg_len = c_end - ch_start + 1;

    chord_track(ch_start:c_end) = chord_track(ch_start:c_end) + chord_y(1:seg_len);
end

% Normalize
if max(abs(melody_track)) > 0
    melody_track = melody_track / max(abs(melody_track));
end
if max(abs(chord_track)) > 0
    chord_track = chord_track / max(abs(chord_track));
end

% Mix
final_audio = GuitarBackend.play_together(melody_track * 0.65, chord_track * 0.35, Fs);

% Save final song
fprintf('Saving song...\n');

filepath = fullfile(pwd, 'RowYourBoat.wav');
audiowrite(filepath, final_audio, Fs);

fprintf('Saved: %s\n', filepath);
fprintf('\nDONE \n');