function [ R, T ] = LPnL_Bar_ENull_AOR_wrapper( X_W, x_c )
%LPNL_BAR_ENULL_AOR_WRAPPER Camera pose estimation from line correspondences using
% the LPnL_Bar_ENull method with Algebraic Outlier Rejection module.
%
%   X_W - 4x(2N) matrix of 3D line endpoints [X; Y; Z; W]
%   x_c - 3x(2N) matrix of 2D line endpoints [x; y; w]
%   ... where N = number of line segments.
%
%   The 3D world coordinate system is right-handed.
%   The 3D camera coordinate system is right-handed: X-right, Y-up, Z-back.

	MIN_LINES = 4;

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
	
	
	%% Prepare input
	% 3D
	for i = 1:4
		X_W(i,:) = X_W(i,:) ./ X_W(end,:);
	end
	X1_W = X_W(:, 1:2:end);
	X2_W = X_W(:, 2:2:end);
	
	% 2D
	x_c = diag([1; -1;  1]) * x_c;
	for i = 1:3
		x_c(i,:) = x_c(i,:) ./ x_c(end,:);
	end
	x1_c = x_c(:, 1:2:end);
	x2_c = x_c(:, 2:2:end);
	
	%% Call LPnL_Bar_ENull with AOR
	[R_ENull, T_ENull] = RLPnL_ENull(x1_c(1:2,:), x2_c(1:2,:), X1_W(1:3,:), X2_W(1:3,:));

	%% Convert output
	R = diag([-1; 1; -1]) * R_ENull;
	T = R_ENull' * T_ENull;
	
	return;
end

