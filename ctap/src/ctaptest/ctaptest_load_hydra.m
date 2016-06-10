function load_hydra()
	fid = fopen('hydra.txt');
	str = fgetl(fid);
	while ischar(str)
		fprintf(1, '%s\n', str);
		str = fgetl(fid);
	end
	fclose(fid);
	pause(2);
end
