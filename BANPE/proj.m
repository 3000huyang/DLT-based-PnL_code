function O = proj( I )
%PROJ �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
    if (size(I,1) ~= 3)
		error('3D line endpoints have to be homogeneous coordinates - 4-tuples [x; y; z; w].');
    end
    O = [I(1,:)./I(3,:);I(2,:)./I(3,:)];
end

