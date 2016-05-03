package.path = '?.lua;' .. package.path
require 'data.lua'

------------
-- Options
------------

cmd = torch.CmdLine()

-- Data files
cmd:text("")
cmd:text("**Data options**")
cmd:text("")
cmd:option('-data_file','data/demo-train.hdf5',[[Path to the training *.hdf5 file 
                                                 from preprocess.py]])
cmd:option('-val_data_file','data/demo-val.hdf5',[[Path to validation *.hdf5 file 
                                                 from preprocess.py]])
cmd:option('-save_file', 'seq2seq_lstm', [[Save file name (model will be saved as 
                         savefile_epochX_PPL.t7 where X is the X-th epoch and PPL is 
                         the validation perplexity]])
cmd:option('-train_from', '', [[If training from a checkpoint then this is the path to the
                                pretrained model.]])

-- RNN model specs
cmd:text("")
cmd:text("**Model options**")
cmd:text("")

cmd:option('-num_layers', 2, [[Number of layers in the LSTM encoder/decoder]])
cmd:option('-hidden_size', 300, [[Size of LSTM hidden states]])
cmd:option('-word_vec_size', 300, [[Word embedding sizes]])
cmd:option('-layer_type', 'lstm', [[Recurrent layer type (rnn, gru, lstm, fast)]])

-- cmd:option('-reverse_src', 0, [[If 1, reverse the source sequence. The original 
--                               sequence-to-sequence paper found that this was crucial to 
--                               achieving good performance, but with attention models this
--                               does not seem necessary. Recommend leaving it to 0]])
-- cmd:option('-init_dec', 1, [[Initialize the hidden/cell state of the decoder at time 
--                            0 to be the last hidden/cell state of the encoder. If 0, 
--                            the initial states of the decoder are set to zero vectors]])

cmd:text("")
cmd:text("**Optimization options**")
cmd:text("")

-- Optimization
cmd:option('-num_epochs', 10, [[Number of training epochs]])
cmd:option('-start_epoch', 1, [[If loading from a checkpoint, the epoch from which to start]])
cmd:option('-param_init', 0.1, [[Parameters are initialized over uniform distribution with support
                                 (-param_init, param_init)]])
cmd:option('-learning_rate', 1, [[Starting learning rate]])
cmd:option('-max_grad_norm', 5, [[If the norm of the gradient vector exceeds this, renormalize it
                                to have the norm equal to max_grad_norm]])
cmd:option('-dropout', 0.3, [[Dropout probability.
                            Dropout is applied between vertical LSTM stacks.]])
cmd:option('-lr_decay', 0.5, [[Decay learning rate by this much if (i) perplexity does not decrease
                        on the validation set or (ii) epoch has gone past the start_decay_at_limit]])
cmd:option('-start_decay_at', 9, [[Start decay after this epoch]])
-- cmd:option('-curriculum', 0, [[For this many epochs, order the minibatches based on source
--                 sequence length. Sometimes setting this to 1 will increase convergence speed.]])
cmd:option('-pre_word_vecs', 'data/word_vecs.hdf5', [[If a valid path is specified, then this will load 
                                      pretrained word embeddings (hdf5 file) on the encoder side. 
                                      See README for specific formatting instructions.]])
cmd:option('-fix_word_vecs_enc', 0, [[If = 1, fix word embeddings on the encoder side]])
cmd:option('-fix_word_vecs_dec', 0, [[If = 1, fix word embeddings on the decoder side]])
cmd:option('-beam_k', 5, [[K value to use with beam search]])
cmd:option('-max_bleu', 4, [[The number of n-grams used in calculating the bleu score]])

cmd:text("")
cmd:text("**Other options**")
cmd:text("")

-- GPU
cmd:option('-gpuid', -1, [[Which gpu to use. -1 = use CPU]])
cmd:option('-gpuid2', -1, [[If this is >= 0, then the model will use two GPUs whereby the encoder
                             is on the first GPU and the decoder is on the second GPU. 
                             This will allow you to train with bigger batches/models.]])

-- Bookkeeping
cmd:option('-save_every', 1, [[Save every this many epochs]])
cmd:option('-print_every', 5, [[Print stats after this many batches]])
cmd:option('-seed', 3435, [[Seed for random initialization]])
cmd:option('-parallel', false, [[When true, uses the parallel library to farm out sgd]])



--load in general functions
funcs = loadfile("functions.lua")
funcs()

opt = cmd:parse(arg)

if opt.parallel then
    require 'parallel'
    require 'torch'
    --load in functions used for parallel
    parallel_funcs = loadfile("parallel_functions.lua")
    parallel_funcs()

    -- protected execution:
    ok,err = pcall(parent)
    if not ok then print(err) parallel.close() end
else
    main()
end