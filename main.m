filename = 'Rot_Grad.csv';
data = csvread(filename);

% extract non-uniform vector and k-space data
non_uniform_vector = data(:, 1);
k_space_data = data(:, 2:end); % columns 2 to end contain k-space data

% apply NUFFT to the k-space data
nufft_results = nufft(k_space_data, non_uniform_vector);

% create sinogram from the absolute values of the NUFFT results
sinogram = abs(nufft_results);

% determine dimensions for back-projected image
num_projections = size(k_space_data, 1); % number of projection angles
num_detectors = size(k_space_data, 2); % number of detector elements

% create an empty back-projected image matrix
back_projected_image = zeros(num_projections, num_detectors);

% perform filtered back projection
for angle = 0:20:340
    % extract the sinogram data for the current projection angle
    projection_data = sinogram(angle/20 + 1, :);
    
    % interpolate the projection data to match the size of the sinogram matrix
    interpolated_projection_data = interp1(1:length(projection_data), projection_data, ...
        linspace(1, length(projection_data), size(k_space_data, 2)), 'linear', 'extrap');
    
    % apply filtered back projection
    back_projected_image = back_projected_image + repmat(interpolated_projection_data, size(k_space_data, 1), 1) ...
        .* repmat(sind(angle), size(k_space_data, 1), 1);
end

% perform FBP reconstruction on the phantom image
sinogram_phantom = radon(phantom(256), 0:340);
back_projected_phantom = iradon(sinogram_phantom, 0:340, 'linear', 'Ram-Lak');

% resize the FBP-reconstructed phantom image to match the size of back_projected_image
back_projected_phantom_resized = imresize(back_projected_phantom, [num_projections, num_detectors]);

% subtract the reconstructed image obtained from NUFFT data from the FBP-reconstructed image pixel by pixel
difference_image = back_projected_phantom_resized - back_projected_image;

figure; % plot original k-space data, sinogram, back-projected image, phantom image, and difference image

% original k-space data
subplot(2, 3, 1);
plot(non_uniform_vector, k_space_data);
xlabel('Non-uniform vector');
ylabel('Magnitude');
title('Original k-space Data');

% sinogram
subplot(2, 3, 2);
imagesc(sinogram);
colormap('gray');
xlabel('Projection Angle');
ylabel('Detector Element');
title('Sinogram');

% plot back-projected image
subplot(2, 3, 3);
imagesc(back_projected_image);
colormap('gray');
xlabel('Detector Element');
ylabel('Projection Angle');
title('Back-Projected Sinogram');

% generate and display phantom image for validation
phantom_image = phantom(256);
subplot(2, 3, 4);
imshow(phantom_image, []);
title('Phantom Image');

% back-projected phantom image
subplot(2, 3, 5);
imshow(back_projected_phantom, []);
title('Back-Projected Phantom Image');

% plot difference image
subplot(2, 3, 6);
imagesc(difference_image);
colormap('gray');
xlabel('Detector Element');
ylabel('Projection Angle');
title('Difference Image (FBP - NUFFT)');
