import React, { useContext, useState, useEffect } from "react";
import clsx from 'clsx';
import TextField from '@material-ui/core/TextField';
import Container from '@material-ui/core/Container';
import Tooltip from '@material-ui/core/Tooltip';
import Typography from "@material-ui/core/Typography";
import FormControl from '@material-ui/core/FormControl';
import FuncsSettingForm from "./FuncsSettingForm"
import { ContextBranch, ContextLinear } from '../Reducers/ContextProvider'
import { makeStyles } from '@material-ui/core/styles';

const useStyles = makeStyles((theme) => ({
    margin: {
        margin: theme.spacing(1),
    },
    withoutLabel: {
        marginTop: theme.spacing(1),
    },
    textField: {
        width: '25ch',
    },
    button: {
        margin: theme.spacing(1),
    },
    customWidth: {
        maxWidth: 500,
    },

}))

const LinearPipesForm = ({ ifLinear, index, mid }) => {
    const classes = useStyles()
    const [inputBranchStates, dispatchB] = useContext(ContextBranch);
    const [inputLinearStates, dispatchL] = useContext(ContextLinear);
    const [inputStates, setInputStates] = useState(() => {
        if (ifLinear) {
            return inputLinearStates;
        } else {
            return inputBranchStates[index].linearSetting;
        }
    });

    useEffect(() => {
        if (ifLinear) {
            setInputStates(inputLinearStates);
        } else {
            setInputStates(inputBranchStates[index].linearSetting);
        }
    }, [inputLinearStates, inputBranchStates])


    const handleLinearPipesInput = (id, event) => {
        const newInputFields = inputStates.map(i => {
            if (id === i.id) {
                i[event.target.name] = event.target.value
                i[event.target.name + 'Check'] = false;
            }
            return i;
        })

        if (ifLinear) {
            dispatchL({ type: 'UPDATE_STEPSETS', data: newInputFields });
        } else {
            const newValue = inputBranchStates;
            newValue[index].linearSetting = newInputFields;
            dispatchB({ type: 'UPDATE_STEPSETS', data: newValue });
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
                            classes={classes}
                            mid={inputField.id}
                            funcsSettings={inputField.funcsSettings} />
                    </FormControl>
                </div>
            ))}
        </Container>
    );
}

export default LinearPipesForm;