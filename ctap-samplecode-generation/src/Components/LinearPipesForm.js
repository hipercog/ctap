import React, { useContext } from "react";
import TextField from '@material-ui/core/TextField';
import Container from '@material-ui/core/Container';
import FuncsSettingForm from "./FuncsSettingForm"
import { Context } from './ContextProvider'
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

const LinearPipesForm = ({ handleLinearPipesInput }) => {
    const classes = useStyles()
    const [inputStates, dispatch] = useContext(Context);


    return (
        <Container maxWidth="sm">
            <form className={classes.root}>
                {inputStates.map((inputField, index) => (
                    <div key={inputField.id}>
                        <h4>stepSet {index + 1}</h4>
                        <TextField
                            name="stepID"
                            label="stepID"
                            variant="filled"
                            helperText="describe main work in this stepSet, eg.'_load'"
                            value={inputField.stepID}
                            onChange={event => handleLinearPipesInput(inputField.id, event)}
                        />

                        <FuncsSettingForm
                            indexm={index}
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