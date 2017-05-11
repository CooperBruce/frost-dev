function obj = compile(obj, export_path, varargin)
    % export the symbolic expressions of the system dynamics matrices and
    % vectors and compile as MEX files.
    %
    % Parameters:
    %  export_path: the path to export the file @type char
    %  varargin: variable input parameters @type varargin
    %   StackVariable: whether to stack variables into one @type logical
    %   File: the (full) file name of exported file @type char
    %   ForceExport: force the export @type logical
    %   BuildMex: flag whether to MEX the exported file @type logical
    %   Namespace: the namespace of the function @type char
    
    % export the mass matrix
    if ~isempty(obj.Mmat)
        export(obj.Mmat,export_path,varargin{:});
    end
    
    % export the drift vector
    if ~isempty(obj.FvecName_)
        prompt = 'Compiling the drift vector often takes very long time. Do you wish to CONTINUE? Y/N [Y]: ';
        str = input(prompt,'s');
        if isempty(str)
            str = 'Y';
        end
        if strcmpi(str,'Y')
            
            
            cellfun(@(x)export(x,export_path,varargin{:}),obj.Fvec,'UniformOutput',false);
        end
    end
    
    
    
    % export the holonomic constraints    
    h_constrs = fieldnames(obj.HolonomicConstraints);
    if ~isempty(h_constrs)
        for i=1:length(h_constrs)
            constr = h_constrs{i};
            export(obj.HolonomicConstraints.(constr),export_path,varargin{:});
           
        end
        
    end
    
    % export the unilateral constraints       
    u_constrs = fieldnames(obj.UnilateralConstraints);
    if ~isempty(u_constrs)
        for i=1:length(u_constrs)
            constr = u_constrs{i};
            export(obj.UnilateralConstraints.(constr),export_path,varargin{:});
        end
        
    end
    
    % export the virtual constraints       
    v_constrs = fieldnames(obj.VirtualConstraints);
    if ~isempty(v_constrs)
        for i=1:length(v_constrs)
            constr = v_constrs{i};
            export(obj.VirtualConstraints.(constr),export_path,varargin{:});
        end
        
    end
    
    % export the event functions
    funcs = fieldnames(obj.EventFuncs);
    if ~isempty(funcs)
        for i=1:length(funcs)
            fun = funcs{i};
            export(obj.EventFuncs.(fun),export_path,varargin{:});
        end        
    end
    
    % call superclass method
    compile@DynamicalSystem(obj, export_path, varargin{:});
    
end