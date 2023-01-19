function sentences = textGen(mdl2,mdl3,options)

    arguments
        mdl2 dictionary
        mdl3 dictionary
        options.firstWord (1,1) string = "<s>";
        options.minLength (1,1) double = 5;
        options.numSamples (1,1) double = 5;
    end
    
    sentences = []; 
    while length(sentences) <= options.numSamples
        outtext = [options.firstWord nextWord(mdl2,options.firstWord)];
        while outtext(end) ~= "</s>"
            outtext = [outtext nextWord(mdl3,outtext(end-1:end))];
            if outtext(end) == "."
                break
            end
        end
        outtext(outtext == "<s>" | outtext == "</s>") = [];
        if length(outtext) >= options.minLength
            sentences = [sentences; strtrim(join(outtext))];
        end
    end
end
