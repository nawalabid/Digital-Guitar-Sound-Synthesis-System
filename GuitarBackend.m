classdef GuitarBackend
    methods (Static)

        % 1. Karplus-Strong Algorithm
        function y = generate_synth(freq, duration, decay, Fs)
            N = round(Fs / freq);
            buffer = rand(N,1) - 0.5;
            num_samples = round(duration * Fs);
            y = zeros(num_samples,1);

            idx = 1;

            % Realism improvement
            previous_sample = 0;
            brightness = 0.98;

            for j = 1:num_samples
                y(j) = buffer(idx);

                next_idx = idx + 1;
                if next_idx > N
                    next_idx = 1;
                end

                avg = decay * (brightness * 0.5 * (buffer(idx) + buffer(next_idx)) ...
                     + (1 - brightness) * previous_sample);

                previous_sample = avg;
                buffer(idx) = avg;
                idx = next_idx;
            end

            % Normalize safely
            if max(abs(y)) > 0
                y = y / max(abs(y));
            end
        end


        % 2. Open string frequencies
        function freqs = get_open_string_freqs()
            freqs = [82.41, 110.00, 146.83, 196.00, 246.94, 329.63];
        end


        % 3. Chord generator
        function chord_audio = generate_chord(notes_to_play, duration, decay, Fs)
            num_samples = round(duration * Fs);
            chord_audio = zeros(num_samples,1);

            for i = 1:length(notes_to_play)
                note_y = GuitarBackend.generate_synth(notes_to_play(i), duration, decay, Fs);
                chord_audio = chord_audio + note_y;
            end

            if max(abs(chord_audio)) > 0
                chord_audio = chord_audio / max(abs(chord_audio));
            end
        end


        % 4. MIX FUNCTION (FIXED - REQUIRED)
        function out = play_together(melody, chords, Fs)
            len = max(length(melody), length(chords));

            melody(end+1:len) = 0;
            chords(end+1:len) = 0;

            out = melody + chords;

            if max(abs(out)) > 0
                out = out / max(abs(out));
            end
        end


        % 5. Save audio (MATLAB SAFE)
        function save_audio(filename, y, Fs)
            if isempty(y)
                error('Audio is empty!');
            end

            if any(isnan(y)) || any(isinf(y))
                error('Invalid audio data detected!');
            end

            % Ensure saving in current folder
            filepath = fullfile(pwd, filename);
            audiowrite(filepath, y, Fs);

            fprintf('Saved: %s\n', filepath);
        end
    end
end