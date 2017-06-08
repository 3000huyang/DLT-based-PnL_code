function [ R, T ] = DLT_Plucker_Lines_AOR( X_W, x_c, reproj_err_th, focal )
%DLT_PLUCKER_LINES_AOR Camera pose estimation from line correspondences using
% the DLT-Plucker-Lines method with Algebraic Outlier Rejection module.
%
%   X_W - 4x(2N) matrix of 3D line endpoints [X; Y; Z; W]
%   x_c - 3x(2N) matrix of 2D line endpoints [x; y; w]
%   ... where N = number of line segments.
%
%   The 3D world coordinate system is right-handed.
%   The 3D camera coordinate system is right-handed: X-right, Y-up, Z-back.

	MIN_LINES = 9;

	%% Input checks
	if (rem(size(X_W, 2), 2))
		error('Number of 3D line endpoints has to be an even number.');
	end
	
	if (size(X_W, 1) ~= 4)
		error('3D line endpoints have to be homogeneous coordinates - 4-tuples [X; Y; Z; W].');
	end
	
	if (size(X_W,2) ~= size(x_c, 2))
		error('Number of 3D and 2D line endpoints has to be equal.');
	end;
	
	if (size(x_c, 1) ~= 3)
		error('2D line endpoints have to be homogeneous coordinates - 3-tuples [x; y; w].');
	end

	N_LINES = size(X_W, 2)/2;
	
	if (N_LINES < MIN_LINES)
		error(['At least ' MIN_LINES ' lines have to be supplied.']);
	end
	

	%% Create Plücker representation of 3D lines
	L_W = pluckerLines(X_W);
	% do NOT prenormalize before AOR
	
	%% Construct 2D lines from endpoints
	l_c = cross(x_c(:, 1:2:end), x_c(:, 2:2:end));
	% do NOT prenormalize before AOR
	
	%% Construct the measurement matrix
	M1 = kron( ...
		[1 1 1 1 1 1], ...
		[ ...
			l_c(3,:)'    zeros(N_LINES,1)   -l_c(1,:)'; ...
			zeros(N_LINES,1)  l_c(3,:)'     -l_c(2,:)'  ...
		] ...
	);
	M2 = kron([L_W L_W]', [1 1 1]);
	M  = M1 .* M2;
		
	%% Algebraic Outlier Rejection (AOR)
	% Based on the paper: L. Ferraz, X. Binefa, F. Moreno-Noguer: Very Fast
	% Solution to the PnP Problem with Algebraic Outlier Rejection, CVPR 2014.
	% Also called "Regression Disgnostics", see http://research.microsoft.com/en-us/um/people/zhang/inria/publis/tutorial-estim/node23.html
	
	is_inlier = true(N_LINES, 1);
	err_th_old = Inf;
	err_th_min = 1.4 * reproj_err_th / abs(focal);
	iter = 0;
	
	% Iterate
	while(true)
		iter = iter+1;
		
		w2 = [is_inlier; is_inlier];
		WM = bsxfun(@times, M, w2); % WM = W * M = diag(w2) * M;

		if (size(WM,1) < size(WM,2))
			[~, ~, V_WM] = svd(WM);
		else
			[~, ~, V_WM] = svd(WM, 'econ');
		end
		
		% Vectorized line projection matrix as the nullspace of the measurement 
		% matrix from the last right singular vector
		p_e = V_WM(:,end);

		residual = M * p_e;
		residual = reshape(residual, N_LINES, 2);
		err = sqrt(sum(residual.^2, 2));
		
		if (iter <= 7)
			err_th = quantile(err, 1 - 0.1*iter);
		else
			err_th = quantile(err, 0.25);
		end

		% check if we have enough (at least 5) correspondences to continue
		if(sum(err <= err_th) < MIN_LINES)
			errors_sorted = sort(err);
			err_th = errors_sorted(MIN_LINES);
		end

		% identify inliers
		is_inlier = true(N_LINES, 1);
		is_inlier( err > max(err_th, err_th_min) ) = false;

		% stop when error threshold stops decreasing
		if(err_th >= err_th_old)
			break;
		else
			err_th_old = err_th;
		end
	
	end % while

	
	%% Compute the final solution from inliers only
	is_inlier = reshape([is_inlier is_inlier]', 2*length(is_inlier), 1);
	[R, T] = DLT_Plucker_Lines(X_W(:, is_inlier), x_c(:, is_inlier));
	return;
end

