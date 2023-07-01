import { makeStyles } from '@material-ui/core/styles';

export const FormControlStyles = makeStyles((theme) => ({
    margin: {
        margin: theme.spacing(1),
    },
    withoutLabel: {
        marginTop: theme.spacing(1),
    },
    textField: {
        width: '25ch',
    },
    words: {
        textAlign: "center",
    },
    customWidth: {
        maxWidth: 500,
    },
}));