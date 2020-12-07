import React, { useContext } from "react";
import TextField from '@material-ui/core/TextField';
import Container from '@material-ui/core/Container';
import FuncsSettingForm from "./FuncsSettingForm"
import { ContextBranch, ContextLinear } from './ContextProvider'
import { makeStyles } from '@material-ui/core/styles';

const useStyles = makeStyles((theme) => ({
    root: {
        '& .MuiTextField-root': {
            margin: theme.spacing(1),
            width: '50ch'
        },
    },
    button: {
        margin: theme.spacing(1),
    }

}))

const LinearPipesForm = ({ ifLinear, index, mid }) => {
    const classes = useStyles()
    const [inputBranchStates, dispatchB] = useContext(ContextBranch);
    const [inputLinearStates, dispatchL] = useContext(ContextLinear);
    
    // console.log(inputLinearStates)
    //console.log(inputBranchStates)
    let inputStates = [];
    if (ifLinear) {
        //console.log('???')
        inputStates = inputLinearStates;
    } else {
        console.log('!!!')
        inputStates = inputBranchStates[index].lindearSetting; 
    }

    const handleLinearPipesInput = (id, event) => {
        const newInputFields = inputStates.map(i => {
            if (id === i.id) {
                i[event.target.name] = event.target.value
                i[event.target.name + 'Check'] = false;
            }
            return i;
        })
        if (ifLinear) {
            dispatchL({ type: 'UPDATE_STEPSETS', data: newInputFields })
        } else {
            const newValue = inputBranchStates;
            newValue[index].lindearSetting = newInputFields;
            dispatchB({ type: 'UPDATE_STEPSETS', data: newValue })
        }
    }

    //console.log(inputStates)

    return (
        <Container maxWidth="sm">
            <form className={classes.root}>
                {inputStates.map((inputField, indexf) => (
                    <div key={inputField.id}>
                        <h4>stepSet {indexf + 1}</h4>
                        <TextField
                            error={inputField.stepIDCheck}
                            name="stepID"
                            label="stepID"
                            variant="filled"
                            helperText={inputField.stepIDCheck ? 'The field cannot be empty. Please enter a value' : "describe main work in this stepSet, eg.'_load'"}
                            value={inputField.stepID}
                            onChange={event => handleLinearPipesInput(inputField.id, event)}
                        />

                        <FuncsSettingForm
                            ifLinear={ifLinear}
                            index={index}
                            indexm={indexf}
                            classes={classes}
                            mid={inputField.id}
                            funcsSettings={inputField.funcsSettings} />
                    </div>
                ))}
            </form>
        </Container>
    );
}

export default LinearPipesForm;