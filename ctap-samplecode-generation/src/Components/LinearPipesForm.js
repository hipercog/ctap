import React, { useContext, useState, useEffect } from "react";
import clsx from 'clsx';
import TextField from '@material-ui/core/TextField';
import Container from '@material-ui/core/Container';
import Tooltip from '@material-ui/core/Tooltip';
import Typography from "@material-ui/core/Typography";
import FormControl from '@material-ui/core/FormControl';
import FuncsSettingForm from "./FuncsSettingForm"
import { ContextBranch, ContextLinear } from '../Reducers/ContextProvider'
import {FormControlStyles} from '../Styles/FormControlStyles'

const LinearPipesForm = ({ ifLinear, index, mid }) => {
    const classes = FormControlStyles()
    const [inputBranchStates, dispatchB] = useContext(ContextBranch);
    const [inputLinearStates, dispatchL] = useContext(ContextLinear);
    const [inputStates, setInputStates] = useState(() => {
        if (ifLinear) {
            return inputLinearStates;
        } else {
            return inputBranchStates[index].linearSettings;
        };
    });

    // set current input states based on pipe type
    useEffect(() => {
        if (ifLinear) {
            setInputStates(inputLinearStates);
        } else {
            setInputStates(inputBranchStates[index].linearSettings);
        }
    }, [inputLinearStates, inputBranchStates]); // eslint-disable-line react-hooks/exhaustive-deps

    // manage input fields
    const handleLinearPipesInput = (id, event) => {
        const newInputFields = inputStates.map(i => {
            if (id === i.id) {
                i[event.target.name] = event.target.value
                i[event.target.name + 'Check'] = false;
            }
            return i;
        })

        if (ifLinear) {
            dispatchL({ type: 'UPDATE', data: newInputFields });
        } else {
            const newValue = inputBranchStates;
            newValue[index].linearSettings = newInputFields;
            dispatchB({ type: 'UPDATE', data: newValue });
        }
        setInputStates(newInputFields);
    }

    return (
        <Container maxWidth="md" >
            {inputStates.map((inputField, indexf) => (
                <div key={inputField.id}>
                    <h4>stepSet {indexf + 1}</h4>
                    <FormControl className={clsx(classes.margin, classes.textField, classes.withoutLabel)}>
                        <Tooltip title={<Typography variant='body2'>{`describe main work in this stepSet, eg.'_load'`}</Typography>} classes={{ tooltip: classes.customWidth }}>
                            <TextField
                                variant="outlined"
                                error={inputField.stepIDCheck}
                                name="stepID"
                                label="stepID"
                                helperText={inputField.stepIDCheck ? 'The field cannot be empty. Please enter a value' : null}
                                value={inputField.stepID}
                                onChange={event => handleLinearPipesInput(inputField.id, event)}
                            />
                        </Tooltip>
                    </FormControl>
                    <FormControl className={clsx(classes.margin, classes.withoutLabel)}>
                        <FuncsSettingForm
                            ifLinear={ifLinear}
                            index={index}
                            indexm={indexf}
                            mid={inputField.id}
                            funcsSettings={inputField.funcsSettings} />
                    </FormControl>
                </div>
            ))}
        </Container>
    );
}

export default LinearPipesForm;