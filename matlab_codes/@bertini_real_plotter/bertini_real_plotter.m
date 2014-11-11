%a class for plotting the data from a bertini_real run of any computable
%dimension
%
%
% options: 
%	'autosave'
%	'vertices', 'vert'
%	'filename'
%	'proj'
%	'mono', 'monocolor'
%	'labels'
%
%
%
%
classdef bertini_real_plotter < handle
	
	
	properties
		BRinfo = [];
% 		scene = scene_manipulator();
		
		window = [20 20 1280 720];
		figures = []
		axes = [];
		handles = [];
		legend = [];
		filename = [];
		
		panels = [];
		buttons = [];
		switches = [];
		checkboxes = [];
		
		scene = [];
		
		dimension = -1;
		
		indices = [];
		
		options = [];
		
		is_bounded = [];
		fv = [];
		
		cam_pos = [];
		
		format = '';
		format_flag = '';
	end
	
	methods
		
		
		function br_plotter = bertini_real_plotter(varargin)
			
			set_default_options(br_plotter);
			
			set_options(br_plotter,varargin);
			
			
			load_data(br_plotter);
			
			if br_plotter.options.use_custom_projection
				preprocess_data(br_plotter);
			end
			
			get_indices(br_plotter);
			
			plot(br_plotter);
		end %re: bertini_real_plotter() constructor
		
		
		
		function set_default_options(br_plotter)
			br_plotter.options.use_custom_projection = false;
			br_plotter.options.markersize = 10;
			br_plotter.options.sample_alpha = 0.5;
			br_plotter.options.face_alpha = 0.5;
			br_plotter.options.edge_alpha = 0.4;
			br_plotter.options.fontsizes.legend = 12;
			br_plotter.options.fontsizes.labels = 16;
			br_plotter.options.fontsizes.axis = 20;
			br_plotter.options.line_thickness = 3;
			br_plotter.options.autosave = false;
			br_plotter.options.labels = true;
			br_plotter.options.monocolor = false;
			br_plotter.options.render_vertices = true;
		end
		
		
		function set_options(br_plotter,command_line_options)
			
			
			if mod(length(command_line_options),2)~=0
				error('must have option-value pairs');
			end
			
			
			for ii = 1:2:length(command_line_options)-1
				
				switch command_line_options{ii}
					case 'autosave'
						
						tentative_arg = command_line_options{ii+1};
						
						if ischar(tentative_arg)
							switch tentative_arg
								case {'y','yes','true'}
									br_plotter.options.autosave = true;
								case {'n','no','false'}
									br_plotter.options.autosave = false;
								otherwise
									error('bad option %s for autosave',tentative_arg);
							end
							
						else
							if tentative_arg==1
								br_plotter.options.autosave = true;
							elseif tentative_arg==0
								br_plotter.options.autosave = false;
							else
								error('bad option %f for autosave',tentative_arg);
							end
						end
						
					case {'vertices','vert'}
						
						tentative_arg = command_line_options{ii+1};
						
						if ischar(tentative_arg)
							switch tentative_arg
								case {'y','yes','true'}
									br_plotter.options.render_vertices = true;
								case {'n','no','false'}
									br_plotter.options.render_vertices = false;
								otherwise
									error('bad option %s for vertices',tentative_arg);
							end
							
						else
							if tentative_arg==1
								br_plotter.options.render_vertices = true;
							elseif tentative_arg==0
								br_plotter.options.render_vertices = false;
							else
								error('bad option %f for vertices',tentative_arg);
							end
						end
						
						
					case 'filename'
						br_plotter.filename = command_line_options{ii+1};
						if ~ischar(br_plotter.filename)
							error('filename argument must be a filename')
						end
					case 'proj'


						tmp = command_line_options{ii+1};

						if isa(tmp,'function_handle')
							br_plotter.options.custom_projection = tmp;
							br_plotter.options.use_custom_projection = true;
						elseif strcmpi(tmp,'natural')
	
						else
							error('value for ''proj'' must be a function handle or ''natural''');
						end


					case {'mono','monocolor'}
						br_plotter.options.monocolor = true;
						
						tentative_color = command_line_options{ii+1};
						
						
						
						if ischar(tentative_color)
							switch tentative_color
								case 'r'
									br_plotter.options.monocolor_color = [1 0 0];
								case 'g'
									br_plotter.options.monocolor_color = [0 1 0];
								case 'b'
									br_plotter.options.monocolor_color = [0 0 1];
								case 'm'
									br_plotter.options.monocolor_color = [1 0 1];
								case 'c'
									br_plotter.options.monocolor_color = [0 1 1];
								case 'y'
									br_plotter.options.monocolor_color = [1 1 0];
								case 'k'
									br_plotter.options.monocolor_color = [0 0 0];
								
								otherwise
									error('input color string must be one of r g b m c y k.  you can also specify a 1x3 RGB color vector');
							end
						else
							[m,n] = size(tentative_color);
							if and(m==1,n==3)
								br_plotter.options.monocolor_color = tentative_color;
							else
								error('explicit color for monocolor surfaces must be a 1x3 RGB vector');
							end
							
						end
						
					case 'labels'
						tentative_arg = command_line_options{ii+1};
						
						if ischar(tentative_arg)
							switch tentative_arg
								case {'y','yes','true'}
									br_plotter.options.labels = true;
								case {'n','no','false'}
									br_plotter.options.labels = false;
								otherwise
									error('bad option %s for labels',tentative_arg);
							end
							
						else
							if tentative_arg==1
								br_plotter.options.labels = true;
							elseif tentative_arg==0
								br_plotter.options.labels = false;
							else
								error('bad option %f for labels',tentative_arg);
							end
						end
						
					otherwise
						error('unexpected option name ''%s''',command_line_options{ii})
				end
			end
		end
		
		
		function load_data(br_plotter)
			
			if isempty(br_plotter.filename)
				prev_filenames = dir('BRinfo*.mat');
				
				if isempty(prev_filenames)
					error('no obvious BRinfo files to load');
				end
				
				max_found = -1;

				for ii = 1:length(prev_filenames)
					curr_name = prev_filenames(ii).name;
					curr_num = str2double(curr_name(7:end-4));
					if max_found < curr_num
						max_found = curr_num;
					end

				end
				br_plotter.filename = ['BRinfo' num2str(max_found) '.mat'];
			end
			
			
			
			if isempty(dir(br_plotter.filename))
				error('nexists file with name ''%s''',br_plotter.filename);
			end
			
			
			file_variables = whos('-file',br_plotter.filename);
			
			if ismember('BRinfo', {file_variables.name})
				temp = load(br_plotter.filename);
				br_plotter.BRinfo = temp.BRinfo;
			else
				error('file ''%s'' does not contain variable ''BRinfo''',br_plotter.filename);
			end
			
			
			
			
			

			[br_plotter.options.containing, br_plotter.options.basename, ~] = fileparts(pwd);

			br_plotter.dimension = br_plotter.BRinfo.dimension;

		end
		
		
		function plot(br_plotter)
			
			
			setupfig(br_plotter);
			
			
			switch br_plotter.dimension
				case 1
					curve_plot(br_plotter);

				case 2	
					surface_plot(br_plotter);

				otherwise

			end

			if ~isempty(br_plotter.legend)
				render_legends(br_plotter);
			end
			
			
			button_setup(br_plotter);
			
			controls(br_plotter);
			
			
			br_plotter.options.plotted = 1;
			
			
			if br_plotter.options.autosave
				try
					save_routine(br_plotter);
				catch
					display('saving render not completed');
				end
			end
			
			
		end
		
		
		function set_label_text_size(br_plotter,~,~,new_size)
			
			f = fieldnames(br_plotter.handles.vertex_text);
			
			for ii = 1:length(f)
				set(br_plotter.handles.vertex_text.(f{ii}),'FontSize',new_size);
			end
			
			
			switch br_plotter.dimension
				case 1
					
					
				case 2
					all_edge_labels = [br_plotter.handles.critcurve_labels;...
								br_plotter.handles.spherecurve_labels;...
								br_plotter.handles.midtext;...
								br_plotter.handles.crittext;...
								br_plotter.handles.singtext];
					
					set(all_edge_labels,'FontSize',new_size);
				otherwise
					
					
			end
			
			br_plotter.options.fontsizes.labels = new_size;
		end
	
		function set_legend_text_size(br_plotter,~,~,new_size)
			set(br_plotter.handles.legend,'FontSize',new_size);
			br_plotter.options.fontsizes.legend = new_size;
		end
		
		function set_axis_text_size(br_plotter,~,~,new_size)
			set(br_plotter.axes.main,'FontSize',new_size);
			br_plotter.options.fontsizes.axis = new_size;
		end
		
		
% 		% the deletion call
% 		function delete(br_plotter)
% 			if ~isempty(br_plotter.figures)
% 				if ishandle(br_plotter.figures.main)
% 					delete(br_plotter.figures.main);
% 				end
% 			end
% 		end 
		
		
		
		
		
		% declared headers for functions in other files.
		
		preprocess_data(br_plotter)

		get_indices(br_plotter)
		
		setupfig(br_plotter,varargin)
		
		create_axes(br_plotter)
		label_axes(br_plotter)
		sync_axes(br_plotter)
		
		visibility_setup(br_plotter)
		
		surface_plot(br_plotter)
		handles = plot_surface_edges(br_plotter)
		
		
		curve_plot(br_plotter)
		
		handles = plot_curve_samples(br_plotter,sampler_data,style)
		
		% common to all dimensions
		sphere_plot(br_plotter)
		plot_vertices(br_plotter)
		
		plot_edge_points(br_plotter)
		
		
		
		render_legends(br_plotter)
		
		
		
		
		% calls the initial_visibility, visibility_setup, and
		% twiddle_visibility functions
		controls(br_plotter)
		
		camera_setup(br_plotter)
		
		center_camera_on_selected_point(br_plotter,source, event)
		
		save_routine(br_plotter,varargin) % is a callback function
		render_into_file(br_plotter)
		
		
		% setup the interactive buttons
		button_setup(br_plotter)
		
		
		
		%http://www.mathworks.com/help/matlab/matlab_oop/class-methods-for-graphics-callbacks.html
		
		
		change_alpha(br_plotter,source,event) % is a callback function
		change_text_size(br_plotter,source,event)% is a callback function

		set_initial_visibility(br_plotter)
		twiddle_visibility(br_plotter)
		
		flip_switch(br_plotter,srcHandle,eventData,varargin)
		
		
		
	
		
				
				
	end%re: methods
	
	

	
end