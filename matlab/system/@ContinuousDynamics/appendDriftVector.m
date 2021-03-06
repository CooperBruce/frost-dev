function obj = appendDriftVector(obj, vf)
    % Append additional vf to the drift vector field Fvec(x) or Fvec(x,dx) of the
    % system
    %
    % Parameters:
    %  vf: the f(x) @type cell
    
    % Ensure that obj.Fvec has been created
    assert(~isempty(obj.Fvec),...
                'Drift vector is empty! You must run configureDynamics before appending entries to the drift vector.');
    
    % validate the inputs vf(x,dx)
    if ~iscell(vf), vf = {vf}; end
    for i=1:numel(vf)
        %         assert((length(vf{i})==obj.numState) && isvector(vf{i}),...
        %             'The %d-th drift vector field should be a (%d x 1) column vector.',i,obj.numState);
        if isa(vf{i},'SymFunction')
            vars = vf{i}.Vars;
            if strcmp(obj.Type,'SecondOrder') % second order system
                assert(length(vars)==2 && vars{1} == obj.States.x && vars{2}==obj.States.dx,...
                    'The SymFunction (vf{%d}) must be a function of states (x) and (dx).',i);
            else % first order system
                assert(length(vars)==1 && vars{1} == obj.States.x,...
                    'The SymFunction (vf{%d}) must be a function of states (x).',i);
            end
        else
            s_vf = SymExpression(vf{i});
            fvec_name = ['Fvec' num2str(i) '_' obj.Name];
            if strcmp(obj.Type,'SecondOrder') % second order system
                sfun_vf = SymFunction(fvec_name,s_vf,{obj.States.x,obj.States.dx});
            else                         % first order system
                sfun_vf = SymFunction(fvec_name,s_vf,{obj.States.x});
            end
            vf{i} = sfun_vf;
        end
        
        % Ensure that the entry does not already exist
        exist_indices = strfind(obj.FvecName_, vf{i}.Name);
        assert(isempty(find(~cellfun(@isempty,exist_indices), 1)),...
                    'The SymFunction (vf{%d}) with name "%s" already exists in the drift vector.',i, vf{i}.Name);
    end

    obj.Fvec = [obj.Fvec; vf];
    obj.FvecName_ = [obj.FvecName_; cellfun(@(f)f.Name, vf,'UniformOutput',false)];

end