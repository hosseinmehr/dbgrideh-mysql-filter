procedure TForm1.dbg1ApplyFilter(Sender: TObject);
const
    // RelaceFieldsArray: array of array of string = [['module_id','module_name'], ['office_id','office_name'], ['user_id_creatore','user_name_creatore']];
    RelaceFieldsArray: array of array of string = [
        ['module_name', 'm.name'],
        ['office_name', 'o.name'],
        ['user_name_creatore', 'u.name'],
        ['=NULL',' IS NULL'],
        ['= NULL',' IS NULL'],
        ['<>NULL',' IS NOT NULL'],
        ['<> NULL',' IS NOT NULL']
        ];
var
    FilterExpression: string;
    i: Integer;
    FirstCondition: Boolean;
    FieldName, UserCondition, UserConditiontmp, UserCondition2: string;
    MappedCondition, ORMappedCondition, ANDMappedCondition: string;
    HasOperator: Boolean;
    ORConditions, ANDConditions: TArray<string>;
    OperatorIndex, OperatorPos: Integer;
    cOperator, Value: string;

begin
    // Initialize the filter expression
    FilterExpression := '';

    // Iterate through the columns of the DBGrid
    for i := 0 to dbg1.Columns.Count - 1 do
    begin
        // Check if the column has a filter condition set
        if dbg1.Columns[i].STFilter.ExpressionStr <> '' then
        begin
            // Get the field name associated with the column
            FieldName := dbg1.Columns[i].FieldName;

            // Retrieve the user-typed condition from the filter expression
            UserCondition := dbg1.Columns[i].STFilter.ExpressionStr;

            UserCondition := StringReplace(UserCondition,'!','NOT ',[rfReplaceAll]);
            UserCondition := StringReplace(UserCondition,'~','LIKE ',[rfReplaceAll]);
            UserCondition := UpperCase(UserCondition);

            // Split the UserCondition by logical operators to handle multiple conditions on the same field
            ORConditions := UserCondition.Split(['OR'], TStringSplitOptions.ExcludeEmpty);

            // Combine the conditions for the same field using logical operators
            ORMappedCondition := '';
            for UserCondition in ORConditions do
            begin
                UserConditiontmp := Trim(UserCondition);
                ANDConditions := UserConditiontmp.Split(['AND'], TStringSplitOptions.ExcludeEmpty);
                ANDMappedCondition := '';
                for UserCondition2 in ANDConditions do
                begin
                    UserConditiontmp := Trim(UserCondition2);
                    OperatorPos := PosOperator(UserConditiontmp, OperatorIndex);
                    HasOperator := (OperatorPos > 0);
                    if HasOperator then
                    begin
                        if Pos('''', UserConditiontmp) > 0 then
                        begin
                            UserConditiontmp := Format('%s %s', [FieldName, UserConditiontmp])
                        end
                        else
                        begin
                            cOperator := Copy(UserConditiontmp, OperatorPos, Length(Operators[OperatorIndex]));
                            Value := Trim(Copy(UserConditiontmp, OperatorPos + Length(Operators[OperatorIndex]), Length(UserConditiontmp) - OperatorPos));
                            // Construct the condition with quotes around the value
                            if(Operators[OperatorIndex] = 'IN') or (Operators[OperatorIndex]='NOT IN') or(UpperCase(Value)='NULL') then
                                UserConditiontmp := Format('%s %s %s', [FieldName, cOperator, Value])
                            else
                                UserConditiontmp := Format('%s %s ''%s''', [FieldName, cOperator, Value]);
                        end;
                    end
                    else
                    begin
                        if Pos('%', UserConditiontmp) > 0 then
                        begin
                            if Pos('''', UserConditiontmp) > 0 then
                                UserConditiontmp := Format('%s LIKE %s', [FieldName, UserConditiontmp])
                            else
                                UserConditiontmp := Format('%s LIKE ''%s''', [FieldName, UserConditiontmp])
                        end
                        else
                        begin
                            if (Pos('''', UserConditiontmp) > 0) or (Pos('NULL', UserConditiontmp) > 0) then
                                UserConditiontmp := Format('%s = %s', [FieldName, UserConditiontmp])
                            else
                                UserConditiontmp := Format('%s = ''%s''', [FieldName, UserConditiontmp])
                        end;
                    end;

                    if ANDMappedCondition = '' then
                        ANDMappedCondition := UserConditiontmp
                    else
                        ANDMappedCondition := ANDMappedCondition + ' AND ' + UserConditiontmp;
                end;

                // Trim the condition and prepend the column name
                if ORMappedCondition = '' then
                    ORMappedCondition := ANDMappedCondition
                else
                    ORMappedCondition := ORMappedCondition + ' OR ' + ANDMappedCondition;
            end;

            // Remove trailing space
            MappedCondition := Trim(ORMappedCondition);

            // Combine the condition with the previous ones using logical operators
            if FilterExpression <> '' then
                FilterExpression := FilterExpression + ' AND ';

            FilterExpression := FilterExpression + MappedCondition;

            // Track if this is the first condition
            if FilterExpression <> '' then
                FirstCondition := False;
        end;
    end;

    // Apply the combined filter expression to the dataset
    if FilterExpression <> '' then
    begin
        for i := 0 to High(RelaceFieldsArray) do
        begin
            FilterExpression := StringReplace(FilterExpression, RelaceFieldsArray[i, 0], RelaceFieldsArray[i, 1], [rfReplaceAll, rfIgnoreCase]);
        end;

        DM.qLicences.SQL[DM.qLicences.SQL.Count - 2] := 'where ' + FilterExpression;
        DM.qLicences.Open;
        // dbg1.DataSource.DataSet.Filter := FilterExpression;
        // dbg1.DataSource.DataSet.Filtered := True;
    end
    else
    begin
        DM.qLicences.SQL[DM.qLicences.SQL.Count - 2] := 'where 1=1 ';
        DM.qLicences.Open;
        // dbg1.DataSource.DataSet.Filter := '';
        // dbg1.DataSource.DataSet.Filtered := False;
    end;

    // Refresh the dataset to reflect the filtered rows in the grid
    // dbg1.DataSource.DataSet.Refresh;
end;
