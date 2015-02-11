function [name, direxists] = eeghub_folder_name(param, main_format, default_number_format, groupdirs)

    if nargin < 3, default_number_format = 4; end
    if nargin < 4, groupdirs = {''}; end    

    [used_fields, matched_strings]  = regexp(main_format, '\((?<parameter>[^\)\%]*)(?<format>[^\)]*)\)', 'names', 'match');
    name = main_format;
    for in=1:length(used_fields)
        % don't like eval, but matlab dont like param.(parameter) when
        % parameter is another structure like parameter.anotherone
        eval(['value = param.' used_fields(in).parameter ';'])
        
        % if numeric, format and convert to string
        if isnumeric(value)
            main_format = used_fields(in).format;
            if isempty(main_format), main_format = default_number_format; end
            value = num2str(value, main_format);
        end
        
        % replace field name with correct value
        name = strrep(name, matched_strings{in}, value);
    end
    
    % no dashes or points, drives bugs in spm
    name = strrep(name, '-', '');
    name = strrep(name, '.', '');
    
    % check if folder existis
    ngroups = length(groupdirs);
    direxists = zeros(1,ngroups);
    for ig=1:ngroups
        thispath = [param.data.path filesep char(groupdirs(ig)) filesep name];
        direxists(ig) = exist(thispath, 'dir');
    end
    
end