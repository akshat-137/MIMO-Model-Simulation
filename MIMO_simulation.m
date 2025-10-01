clc;
clear all;
close all;

num_bits = 100000 ;
SNR_db = 0:2:20 ;
BER_MIMO_spatial = zeros(size(SNR_db)) ; % for SPATIAL MULTIPLEXING
BER_MIMO_alamouti = zeros(size(SNR_db)) ; % for ALAMOUTI CODE

bit_sequence = randi([0 1], num_bits , 1);
BPSK_symbol = 2*bit_sequence-1 ;

for i = 1:length(SNR_db)
    SNR = SNR_db(i) ;
    noise_variance =  10^(-SNR/10) ;

    %% ---- MIMO 2*2 SPATIAL MULTIPLEXING (V-BLAST TYPE) ---

    x = reshape(BPSK_symbol , 2 , []) ;
    H = (randn(2,2,size(x,2)) + 1*j*randn(2,2,size(x,2)))/sqrt(2) ;
    y = zeros(2,size(x,2)) ;

    for k = 1 : size(x,2)
        y(:,k) = H(:,:,k)*x(: ,k) + sqrt(noise_variance/2)*(randn(2,1)+1*j*randn(2,1)) ;
        % Zero-forcing 
        x_hat(:,k) = pinv(H(:,:,k))*y(:,k) ; % pinv() : Moore-Penrose Pseudoinverse function
    end
    detection = real(x_hat(:)) > 0 ;
    BER_MIMO_spatial(i) = mean(detection ~= bit_sequence(1:2*size(x,2))) ;

    %% ---- MIMO 2x2 ALAMOUTI CODING ----

    symbol_1 = BPSK_symbol(1:2:end);
    symbol_2 = BPSK_symbol(2:2:end);
    nBlocks  = length(symbol_1);
    
    alamouti_detection = zeros(2,nBlocks);
    
    for k = 1:nBlocks
        % 2x2 Rayleigh channel (changes per block)
        H = (randn(2,2) + 1j*randn(2,2))/sqrt(2);
    
        % Transmit over channel (2 time slots)
        y1 = H(1,1)*symbol_1(k) + H(2,1)*symbol_2(k) + ...
             sqrt(noise_variance/2)*(randn+1j*randn);
        y2 = H(1,1)*(-conj(symbol_2(k))) + H(2,1)*conj(symbol_1(k)) + ...
             sqrt(noise_variance/2)*(randn+1j*randn);
    
        % Alamouti decoding
        r1 = conj(H(1,1))*y1 + H(2,1)*conj(y2);
        r2 = conj(H(2,1))*y1 - H(1,1)*conj(y2);
    
        % Decision
        alamouti_detection(:,k) = [real(r1) > 0; real(r2) > 0];
    end
    
    BER_MIMO_alamouti(i) = mean(alamouti_detection(:) ~= bit_sequence(1:2*nBlocks));

end

figure;
semilogy(SNR_db, BER_MIMO_spatial, '-o','LineWidth',2); 
hold on;
semilogy(SNR_db, BER_MIMO_alamouti, '-s','LineWidth',2);
grid on; 
xlabel('SNR (dB)'); 
ylabel('BER');
legend('MIMO 2x2 Spatial Multiplexing','MIMO 2x2 Alamouti Coding', Location='best');
title('BER vs SNR Comparison : Spatial vs Alamouti');
