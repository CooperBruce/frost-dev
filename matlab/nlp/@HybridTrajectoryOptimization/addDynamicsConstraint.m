function obj = addDynamicsConstraint(obj, phase)
    % Add system dynamics equations as a set of equality constraints   
    %
    % The full dynamics equations consist of two parts, the
    % Euler-Langrangian dynamics of the rigid body model and the holonomic
    % constraints of the system:
    % \f{eqnarray*}{
    %  D(q)*\ddot{q} + C(q,\dot{q}) + G(q) - Be*u - J^T(q)*Fe &= 0 \\
    %  J(q)*\ddot{q} + \dot{J}(q,\dot{q})*\dot{q} &= 0
    % \f}
    %
    % Parameters:
    % phase: the index of the phase (domain) @type integer

    model_funcs = obj.Funcs.Model;
    
    % extract phase information
    phase_idx = getPhaseIndex(obj, phase);
    phase_info = obj.Phase{phase_idx};
    phase_funcs = obj.Funcs.Phase{phase_idx};
    % Total degrees of freedom of the model
    n_dof = obj.Model.nDof;
    
    % local variable for fast access
    n_node = phase_info.NumNode;
    var_table= phase_info.OptVarTable;
    col_names = phase_info.ConstrTable.Properties.VariableNames;
    domain = obj.Gamma.Nodes.Domain{phase_info.CurrentVertex};
    
    if ~isempty(domain.HolonomicConstr)
        n_constr = getDimension(domain.HolonomicConstr);
        holPos = repmat({{}},1, n_node);
        holVel = repmat({{}},1, n_node);
        holAcc = repmat({{}},1, n_node);
    else
        n_constr = 0;
    end
    dynamics_constr = repmat({{}},1, n_node);
    
    % dynamics constraints are enforced at all nodes
    node_list = 1:n_node;
    
    
    
    for i=node_list
        
        %% Euler-Langrangian Equation
        % D(q)*ddq
        De = NlpFunction('Name','De_ddq',...
            'Dimension',n_dof, 'Type', 'nonlinear',...
            'lb',0,'ub',0,'DepVariables',...
            {{var_table{'Qe',i}{1},var_table{'ddQe',i}{1}}},...
            'Funcs', model_funcs.De_ddq.Funcs);
        
        % C(q,dq)
        Ce_dq_p1 = NlpFunction('Name','Ce_dq_p1',...
            'Dimension',n_dof, 'Type', 'nonlinear',...
            'lb',0,'ub',0,'DepVariables',...
            {{var_table{'Qe',i}{1},var_table{'dQe',i}{1}}},...
            'Funcs', model_funcs.Ce_dq_p1.Funcs);
        
        Ce_dq_p2 = NlpFunction('Name','Ce_dq_p2',...
            'Dimension',n_dof, 'Type', 'nonlinear',...
            'lb',0,'ub',0,'DepVariables',...
            {{var_table{'Qe',i}{1},var_table{'dQe',i}{1}}},...
            'Funcs', model_funcs.Ce_dq_p2.Funcs);
        
        Ce_dq_p3 = NlpFunction('Name','Ce_dq_p3',...
            'Dimension',n_dof, 'Type', 'nonlinear',...
            'lb',0,'ub',0,'DepVariables',...
            {{var_table{'Qe',i}{1},var_table{'dQe',i}{1}}},...
            'Funcs', model_funcs.Ce_dq_p3.Funcs);
        
        % G(q)
        Ge = NlpFunction('Name','Ge',...
            'Dimension',n_dof, 'Type', 'nonlinear',...
            'lb',0,'ub',0, 'DepVariables',...
            {{var_table{'Qe',i}{1}}},...
            'Funcs', model_funcs.Ge.Funcs);

        % - B*u - J^T(q)*Fe
        control = NlpFunction('Name','Control',...
            'Dimension',n_dof, 'Type', 'nonlinear',...
            'lb',0,'ub',0,'DepVariables',...
            {{var_table{'Qe',i}{1}, var_table{'U',i}{1}, var_table{'Fe', i}{1}}},...
            'Funcs', phase_funcs.control.Funcs);
        
        % Composite function
        dynamics_constr{i} = {NlpFunctionSum('Name', 'dynamics',...
            'Dimension',n_dof,'Type','nonlinear',...
            'lb',0,'ub',0,...
            'DependentFuncs',{{De,Ce_dq_p1,Ce_dq_p2,Ce_dq_p3,Ge,control}})};
        
        %% Holonomic Constraints
        if n_constr > 0
            
            
            holAcc{i} = {NlpFunction('Name','holAcc',...
                'Dimension',n_constr, 'Type', 'nonlinear',...
                'lb',0,'ub',0,'DepVariables',...
                {{var_table{'Qe',i}{1},var_table{'dQe',i}{1},var_table{'ddQe',i}{1}}},...
                'Funcs', phase_funcs.holAcc.Funcs)};
        end
    end
    
    if n_constr > 0
%         % In addition, we enforce the holonomic constraint value is equal to
%         % the desired values at the first node.
%         holPos{1} = {NlpFunction('Name','holPos',...
%             'Dimension',n_constr, 'Type', 'nonlinear',...
%             'lb',0,'ub',0, 'DepVariables',...
%             {{var_table{'Qe',1}{1},var_table{'H',1}{1}}},...
%             'Funcs', phase_funcs.holPos.Funcs)};
%         % The velocity (1st order time derivatives) of the holonomic
%         % constraints to be zero at the first node
%         holVel{1} = {NlpFunction('Name','holVel',...
%             'Dimension',n_constr, 'Type', 'nonlinear',...
%             'lb',0,'ub',0, 'DepVariables',...
%             {{var_table{'Qe',1}{1},var_table{'dQe',1}{1}}},...
%             'Funcs', phase_funcs.holVel.Funcs)};
    end
    
    % add to the constraints table
    if n_constr > 0
        obj.Phase{phase_idx}.ConstrTable = [...
            obj.Phase{phase_idx}.ConstrTable;...
            cell2table(dynamics_constr,'RowNames',{'dynamics'},'VariableNames',col_names);...
            cell2table(holAcc,'RowNames',{'holAcc'},'VariableNames',col_names);...
            cell2table(holVel,'RowNames',{'holVel'},'VariableNames',col_names);...
            cell2table(holPos,'RowNames',{'holPos'},'VariableNames',col_names)];
    else
        obj.Phase{phase_idx}.ConstrTable = [...
            obj.Phase{phase_idx}.ConstrTable;...
            cell2table(dynamics_constr,'RowNames',{'dynamics'},'VariableNames',col_name)];
    end
end