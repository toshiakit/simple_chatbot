function nextword = nextWord(mdl,prev)

    arguments
        mdl dictionary
        prev string
    end

    vocab = keys(mdl);
    vocab = split(vocab);
    if size(vocab,2) < 3
        candidates = vocab(vocab(:,1) == prev,:);
    else
        candidates = vocab(join(vocab(:,1:end-1)) == join(prev),:);
    end
    prob = mdl(join(candidates));
    candidates = candidates(prob > 0,:);
    prob = prob(prob > 0);
    samples = round(prob * 10000);
    pick = randsample(sum(samples),1);
    if pick > sum(samples(1:end-1))
        nextword = candidates(end);
    else
        ii = 1;
        while sum(samples(1:ii + 1)) < pick
            ii = ii + 1; 
        end
        nextword = candidates(ii,end);
    end
end
