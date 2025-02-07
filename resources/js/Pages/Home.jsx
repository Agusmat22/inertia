import { Link } from "@inertiajs/react";

function Home(){
    return (
        <div>
            <h1>Hola</h1>
            <Link href="/about" >About</Link>
        </div>
    );
}

export default Home;